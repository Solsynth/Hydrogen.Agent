import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/chat/call/exts.dart';
import 'package:solian/widgets/chat/call/participant.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:math' as math;

import '../../widgets/chat/call/controls.dart';

class ChatCall extends StatefulWidget {
  final Call call;

  const ChatCall({super.key, required this.call});

  @override
  State<ChatCall> createState() => _ChatCallState();
}

class _ChatCallState extends State<ChatCall> {
  String? _token;
  String? _endpoint;

  bool _isMounted = false;

  StreamSubscription? _subscription;
  List<MediaDevice> _audioInputs = [];
  List<MediaDevice> _videoInputs = [];

  bool _enableAudio = true;
  bool _enableVideo = false;
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;
  MediaDevice? _videoDevice;
  MediaDevice? _audioDevice;

  final VideoParameters _videoParameters = VideoParametersPresets.h720_169;

  late Room _callRoom;
  late EventsListener<RoomEvent> _callListener;

  List<ParticipantTrack> _participantTracks = [];

  Future<void> checkPermissions() async {
    if (lkPlatformIs(PlatformType.macOS) || lkPlatformIs(PlatformType.linux)) return;
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
  }

  Future<(String, String)> exchangeToken() async {
    await checkPermissions();

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      router.pop();
      throw Error();
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.call.channel.alias}/calls/ongoing/token');

    var res = await auth.client!.post(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      _token = result['token'];
      _endpoint = 'wss://${result['endpoint']}';
      joinRoom(_endpoint!, _token!);
      return (_token!, _endpoint!);
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
      throw Exception(message);
    }
  }

  void joinRoom(String url, String token) async {
    if (_isMounted) {
      return;
    } else {
      _isMounted = true;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      await _callRoom.connect(
        url,
        token,
        roomOptions: RoomOptions(
          dynacast: true,
          adaptiveStream: true,
          defaultAudioPublishOptions: const AudioPublishOptions(
            name: 'call_voice',
            stream: 'call_stream',
          ),
          defaultVideoPublishOptions: const VideoPublishOptions(
            name: 'call_video',
            stream: 'call_stream',
            simulcast: true,
            backupVideoCodec: BackupVideoCodec(enabled: true),
          ),
          defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            params: VideoParameters(
              dimensions: VideoDimensionsPresets.h1080_169,
              encoding: VideoEncoding(maxBitrate: 3 * 1000 * 1000, maxFramerate: 30),
            ),
          ),
          defaultCameraCaptureOptions: CameraCaptureOptions(maxFrameRate: 30, params: _videoParameters),
        ),
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(track: _audioTrack),
          camera: TrackOption(track: _videoTrack),
        ),
      );

      setupRoom();
    } catch (e) {
      final message = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    } finally {
      notify.close();
    }
  }

  void autoPublish() async {
    try {
      if (_enableVideo) await _callRoom.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      await context.showErrorDialog(error);
    }
    try {
      if (_enableAudio) await _callRoom.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      await context.showErrorDialog(error);
    }
  }

  void setupRoom() {
    _callRoom.addListener(onRoomDidUpdate);
    setupRoomListeners();
    sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) => autoPublish());

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }
  }

  void setupRoomListeners() {
    _callListener
      ..on<RoomDisconnectedEvent>((event) async {
        if (event.reason != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Call disconnected... ${event.reason}'),
          ));
        }
        if (router.canPop()) router.pop();
      })
      ..on<ParticipantEvent>((event) => sortParticipants())
      ..on<RoomRecordingStatusChanged>((event) {
        context.showRecordingStatusChangedDialog(event.activeRecording);
      })
      ..on<LocalTrackPublishedEvent>((_) => sortParticipants())
      ..on<LocalTrackUnpublishedEvent>((_) => sortParticipants())
      ..on<TrackSubscribedEvent>((_) => sortParticipants())
      ..on<TrackUnsubscribedEvent>((_) => sortParticipants())
      ..on<ParticipantNameUpdatedEvent>((event) {
        sortParticipants();
      })
      ..on<AudioPlaybackStatusChanged>((event) async {
        if (!_callRoom.canPlaybackAudio) {
          bool? yesno = await context.showPlayAudioManuallyDialog();
          if (yesno == true) {
            await _callRoom.startAudio();
          }
        }
      });
  }

  void sortParticipants() {
    List<ParticipantTrack> userMediaTracks = [];
    List<ParticipantTrack> screenTracks = [];
    for (var participant in _callRoom.remoteParticipants.values) {
      for (var t in participant.videoTrackPublications) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    userMediaTracks.sort((a, b) {
      // Loudest people first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // Last spoke first
      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // Has video first
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // First joined people first
      return a.participant.joinedAt.millisecondsSinceEpoch - b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks = _callRoom.localParticipant?.videoTrackPublications;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: _callRoom.localParticipant!,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: _callRoom.localParticipant!,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    setState(() {
      _participantTracks = [...screenTracks, ...userMediaTracks];
    });
  }

  void onRoomDidUpdate() => sortParticipants();

  void revertDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    if (_audioInputs.isNotEmpty) {
      if (_audioDevice == null && _enableAudio) {
        _audioDevice = _audioInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalAudioTrack();
          setState(() {});
        });
      }
    }

    if (_videoInputs.isNotEmpty) {
      if (_videoDevice == null && _enableVideo) {
        _videoDevice = _videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalVideoTrack();
          setState(() {});
        });
      }
    }
    setState(() {});
  }

  Future<void> setEnableVideo(value) async {
    _enableVideo = value;
    if (!_enableVideo) {
      await _videoTrack?.stop();
      _videoTrack = null;
    } else {
      await changeLocalVideoTrack();
    }
    setState(() {});
  }

  Future<void> setEnableAudio(value) async {
    _enableAudio = value;
    if (!_enableAudio) {
      await _audioTrack?.stop();
      _audioTrack = null;
    } else {
      await changeLocalAudioTrack();
    }
    setState(() {});
  }

  Future<void> changeLocalAudioTrack() async {
    if (_audioTrack != null) {
      await _audioTrack!.stop();
      _audioTrack = null;
    }

    if (_audioDevice != null) {
      _audioTrack = await LocalAudioTrack.create(AudioCaptureOptions(
        deviceId: _audioDevice!.deviceId,
      ));
      await _audioTrack!.start();
    }
  }

  Future<void> changeLocalVideoTrack() async {
    if (_videoTrack != null) {
      await _videoTrack!.stop();
      _videoTrack = null;
    }

    if (_videoDevice != null) {
      _videoTrack = await LocalVideoTrack.createCameraTrack(CameraCaptureOptions(
        deviceId: _videoDevice!.deviceId,
        params: _videoParameters,
      ));
      await _videoTrack!.start();
    }
  }

  @override
  void initState() {
    super.initState();
    _subscription = Hardware.instance.onDeviceChange.stream.listen(revertDevices);
    _callRoom = Room();
    _callListener = _callRoom.createListener();
    Hardware.instance.enumerateDevices().then(revertDevices);
    WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      title: AppLocalizations.of(context)!.chatCall,
      noSafeArea: true,
      hideDrawer: true,
      child: FutureBuilder(
        future: exchangeToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _participantTracks.isNotEmpty
                        ? ParticipantWidget.widgetFor(_participantTracks.first)
                        : Container(),
                  ),
                  if (_callRoom.localParticipant != null)
                    SafeArea(
                      top: false,
                      child: ControlsWidget(_callRoom, _callRoom.localParticipant!),
                    )
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.max(0, _participantTracks.length - 1),
                    itemBuilder: (BuildContext context, int index) => SizedBox(
                      width: 180,
                      height: 120,
                      child: ParticipantWidget.widgetFor(_participantTracks[index + 1]),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void deactivate() {
    _subscription?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    (() async {
      _callRoom.removeListener(onRoomDidUpdate);
      await _callRoom.disconnect();
      await _callListener.dispose();
      await _callRoom.dispose();
    })();
    super.dispose();
  }
}
