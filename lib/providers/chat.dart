import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/chat/call/exts.dart';
import 'package:solian/widgets/exts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatProvider extends ChangeNotifier {
  bool isOpened = false;
  bool isCallShown = false;

  Call? ongoingCall;
  Channel? focusChannel;
  String? focusChannelRealm;
  ChatCallInstance? currentCall;

  PagingController<int, Message>? historyPagingController;

  WebSocketChannel? _channel;

  Future<WebSocketChannel?> connect(AuthProvider auth, {noRetry = false}) async {
    if (auth.client == null) await auth.loadClient();
    if (!await auth.isAuthorized()) return null;

    var ori = getRequestUri('messaging', '/api/ws');
    var uri = Uri(
      scheme: ori.scheme.replaceFirst('http', 'ws'),
      host: ori.host,
      port: ori.port,
      path: ori.path,
      queryParameters: {'tk': Uri.encodeComponent(auth.client!.currentToken!)},
    );

    isOpened = true;

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      if (!noRetry) {
        await auth.client!.refreshToken(auth.client!.currentRefreshToken!);
        connect(auth, noRetry: true);
      } else {
        rethrow;
      }
    }

    _channel!.stream.listen(
      (event) {
        final result = NetworkPackage.fromJson(jsonDecode(event));
        if (focusChannel == null || historyPagingController == null) return;
        switch (result.method) {
          case 'messages.new':
            final payload = Message.fromJson(result.payload!);
            if (payload.channelId == focusChannel?.id) {
              historyPagingController?.itemList?.insert(0, payload);
            }
            break;
          case 'messages.update':
            final payload = Message.fromJson(result.payload!);
            if (payload.channelId == focusChannel?.id) {
              historyPagingController?.itemList =
                  historyPagingController?.itemList?.map((x) => x.id == payload.id ? payload : x).toList();
            }
            break;
          case 'messages.burnt':
            final payload = Message.fromJson(result.payload!);
            if (payload.channelId == focusChannel?.id) {
              historyPagingController?.itemList =
                  historyPagingController?.itemList?.where((x) => x.id != payload.id).toList();
            }
            break;
          case 'calls.new':
            final payload = Call.fromJson(result.payload!);
            if (payload.channelId == focusChannel?.id) {
              setOngoingCall(payload);
            }
            break;
          case 'calls.end':
            final payload = Call.fromJson(result.payload!);
            if (payload.channelId == focusChannel?.id) {
              setOngoingCall(null);
            }
            break;
        }
        notifyListeners();
      },
      onError: (_, __) => Future.delayed(const Duration(seconds: 3), () => connect(auth)),
      onDone: () => Future.delayed(const Duration(seconds: 1), () => connect(auth)),
    );

    return _channel!;
  }

  void disconnect() {
    _channel = null;
    isOpened = false;
  }

  Future<void> fetchMessages(int pageKey, BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;
    if (focusChannel == null || focusChannelRealm == null) return;

    final offset = pageKey;
    const take = 10;

    var uri = getRequestUri(
      'messaging',
      '/api/channels/$focusChannelRealm/${focusChannel!.alias}/messages?take=$take&offset=$offset',
    );

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final items = result.data?.map((x) => Message.fromJson(x)).toList() ?? List.empty();
      final isLastPage = (result.count - pageKey) < take;
      if (isLastPage || result.data == null) {
        historyPagingController!.appendLastPage(items);
      } else {
        final nextPageKey = pageKey + items.length;
        historyPagingController!.appendPage(items, nextPageKey);
      }
    } else if (res.statusCode == 403) {
      historyPagingController!.appendLastPage([]);
    } else {
      historyPagingController!.error = utf8.decode(res.bodyBytes);
    }
  }

  Future<Channel> fetchChannel(BuildContext context, AuthProvider auth, String alias, String realm) async {
    if (focusChannel != null) {
      unFocus();
    }

    var uri = getRequestUri('messaging', '/api/channels/$realm/$alias/availability');
    var res = await auth.client!.get(uri);
    if (res.statusCode == 200 || res.statusCode == 403) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      focusChannel = Channel.fromJson(result);
      focusChannel?.isAvailable = res.statusCode == 200;
      focusChannelRealm = realm;

      if (historyPagingController == null) {
        historyPagingController = PagingController(firstPageKey: 0);
        historyPagingController?.addPageRequestListener((pageKey) => fetchMessages(pageKey, context));
      }

      notifyListeners();

      return focusChannel!;
    } else {
      var message = utf8.decode(res.bodyBytes);
      throw Exception(message);
    }
  }

  Future<Call?> fetchOngoingCall(String alias, String realm) async {
    final Client client = Client();

    var uri = getRequestUri('messaging', '/api/channels/$realm/$alias/calls/ongoing');
    var res = await client.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      ongoingCall = Call.fromJson(result);
      notifyListeners();
      return ongoingCall;
    } else if (res.statusCode != 404) {
      var message = utf8.decode(res.bodyBytes);
      throw Exception(message);
    } else {
      return null;
    }
  }

  bool handleCallJoin(Call call, Channel channel, {Function? onUpdate, Function? onDispose}) {
    if (currentCall != null) return false;

    currentCall = ChatCallInstance(
      onUpdate: () {
        notifyListeners();
        if (onUpdate != null) onUpdate();
      },
      onDispose: () {
        currentCall = null;
        notifyListeners();
        if (onDispose != null) onDispose();
      },
      channel: channel,
      info: call,
    );

    return true;
  }

  void setOngoingCall(Call? item) {
    ongoingCall = item;
    notifyListeners();
  }

  void setCallShown(bool state) {
    isCallShown = state;
    notifyListeners();
  }

  void unFocus() {
    currentCall = null;
    focusChannel = null;
    historyPagingController?.dispose();
    historyPagingController = null;
    notifyListeners();
  }
}

class ChatCallInstance {
  final Function onUpdate;
  final Function onDispose;

  final Call info;
  final Channel channel;

  bool isMounted = false;

  String? token;
  String? endpoint;

  StreamSubscription? subscription;
  List<MediaDevice> audioInputs = [];
  List<MediaDevice> videoInputs = [];

  bool enableAudio = true;
  bool enableVideo = false;
  LocalAudioTrack? audioTrack;
  LocalVideoTrack? videoTrack;
  MediaDevice? videoDevice;
  MediaDevice? audioDevice;

  final VideoParameters videoParameters = VideoParametersPresets.h720_169;

  late Room room;
  late EventsListener<RoomEvent> listener;

  List<ParticipantTrack> participantTracks = [];
  ParticipantTrack? focusTrack;

  ChatCallInstance({
    required this.onUpdate,
    required this.onDispose,
    required this.channel,
    required this.info,
  });

  void init() {
    subscription = Hardware.instance.onDeviceChange.stream.listen(revertDevices);
    room = Room();
    listener = room.createListener();
    Hardware.instance.enumerateDevices().then(revertDevices);
    WakelockPlus.enable();
  }

  Future<void> checkPermissions() async {
    if (lkPlatformIs(PlatformType.macOS) || lkPlatformIs(PlatformType.linux)) {
      return;
    }

    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
  }

  Future<(String, String)> exchangeToken(BuildContext context) async {
    await checkPermissions();

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      onDispose();
      throw Exception('unauthorized');
    }

    var uri = getRequestUri('messaging', '/api/channels/global/${channel.alias}/calls/ongoing/token');

    var res = await auth.client!.post(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      token = result['token'];
      endpoint = 'wss://${result['endpoint']}';
      joinRoom(context, endpoint!, token!);
      return (token!, endpoint!);
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
      throw Exception(message);
    }
  }

  void joinRoom(BuildContext context, String url, String token) async {
    if (isMounted) {
      return;
    } else {
      isMounted = true;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      await room.connect(
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
            name: 'callvideo',
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
          defaultCameraCaptureOptions: CameraCaptureOptions(maxFrameRate: 30, params: videoParameters),
        ),
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(track: audioTrack),
          camera: TrackOption(track: videoTrack),
        ),
      );

      setupRoom(context);
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      notify.close();
    }
  }

  void autoPublish(BuildContext context) async {
    try {
      if (enableVideo) await room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      await context.showErrorDialog(error);
    }
    try {
      if (enableAudio) await room.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      await context.showErrorDialog(error);
    }
  }

  void setupRoom(BuildContext context) {
    room.addListener(onRoomDidUpdate);
    setupRoomListeners(context);
    sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) => autoPublish(context));

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }
  }

  void setupRoomListeners(BuildContext context) {
    listener
      ..on<RoomDisconnectedEvent>((event) async {
        if (event.reason != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Call disconnected... ${event.reason}'),
          ));
        }
        onDispose();
      })
      ..on<ParticipantEvent>((event) => sortParticipants())
      ..on<LocalTrackPublishedEvent>((_) => sortParticipants())
      ..on<LocalTrackUnpublishedEvent>((_) => sortParticipants())
      ..on<TrackSubscribedEvent>((_) => sortParticipants())
      ..on<TrackUnsubscribedEvent>((_) => sortParticipants())
      ..on<ParticipantNameUpdatedEvent>((event) {
        sortParticipants();
      })
      ..on<AudioPlaybackStatusChanged>((event) async {
        if (!room.canPlaybackAudio) {
          bool? yesno = await context.showPlayAudioManuallyDialog();
          if (yesno == true) {
            await room.startAudio();
          }
        }
      });
  }

  void sortParticipants() {
    Map<String, ParticipantTrack> mediaTracks = {};
    for (var participant in room.remoteParticipants.values) {
      mediaTracks[participant.sid] = ParticipantTrack(
        participant: participant,
        videoTrack: null,
        isScreenShare: false,
      );

      for (var t in participant.videoTrackPublications) {
        mediaTracks[participant.sid]?.videoTrack = t.track;
        mediaTracks[participant.sid]?.isScreenShare = t.isScreenShare;
      }
    }

    final mediaTrackList = mediaTracks.values.toList();
    mediaTrackList.sort((a, b) {
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

    ParticipantTrack localTrack = ParticipantTrack(
      participant: room.localParticipant!,
      videoTrack: null,
      isScreenShare: false,
    );
    if (room.localParticipant != null) {
      final localParticipantTracks = room.localParticipant?.videoTrackPublications;
      if (localParticipantTracks != null) {
        for (var t in localParticipantTracks) {
          localTrack.videoTrack = t.track;
          localTrack.isScreenShare = t.isScreenShare;
        }
      }
    }

    participantTracks = [localTrack, ...mediaTrackList];
    if (focusTrack == null) {
      focusTrack = participantTracks.first;
    } else {
      final idx = participantTracks.indexWhere((x) => focusTrack!.participant.sid == x.participant.sid);
      focusTrack = participantTracks[idx];
    }

    onUpdate();
  }

  void revertDevices(List<MediaDevice> devices) async {
    audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    if (audioInputs.isNotEmpty) {
      if (audioDevice == null && enableAudio) {
        audioDevice = audioInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalAudioTrack();
          onUpdate();
        });
      }
    }

    if (videoInputs.isNotEmpty) {
      if (videoDevice == null && enableVideo) {
        videoDevice = videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalVideoTrack();
          onUpdate();
        });
      }
    }

    onUpdate();
  }

  Future<void> setEnableVideo(value) async {
    enableVideo = value;
    if (!enableVideo) {
      await videoTrack?.stop();
      videoTrack = null;
    } else {
      await changeLocalVideoTrack();
    }
    onUpdate();
  }

  Future<void> setEnableAudio(value) async {
    enableAudio = value;
    if (!enableAudio) {
      await audioTrack?.stop();
      audioTrack = null;
    } else {
      await changeLocalAudioTrack();
    }

    onUpdate();
  }

  Future<void> changeLocalAudioTrack() async {
    if (audioTrack != null) {
      await audioTrack!.stop();
      audioTrack = null;
    }

    if (audioDevice != null) {
      audioTrack = await LocalAudioTrack.create(AudioCaptureOptions(
        deviceId: audioDevice!.deviceId,
      ));
      await audioTrack!.start();
    }
  }

  Future<void> changeLocalVideoTrack() async {
    if (videoTrack != null) {
      await videoTrack!.stop();
      videoTrack = null;
    }

    if (videoDevice != null) {
      videoTrack = await LocalVideoTrack.createCameraTrack(CameraCaptureOptions(
        deviceId: videoDevice!.deviceId,
        params: videoParameters,
      ));
      await videoTrack!.start();
    }
  }

  void changeFocusTrack(ParticipantTrack track) {
    focusTrack = track;
    onUpdate();
  }

  void onRoomDidUpdate() => sortParticipants();

  void deactivate() {
    subscription?.cancel();
  }

  void dispose() {
    room.removeListener(onRoomDidUpdate);
    (() async {
      await listener.dispose();
      await room.disconnect();
      await room.dispose();
    })();
    WakelockPlus.disable();
    onDispose();
  }
}
