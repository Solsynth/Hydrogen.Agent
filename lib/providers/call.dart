import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/screens/channel/call/call.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChatCallProvider extends GetxController {
  Rx<Call?> current = Rx(null);
  Rx<Channel?> channel = Rx(null);

  RxBool isReady = false.obs;
  RxBool isMounted = false.obs;
  RxBool isInitialized = false.obs;

  String? token;
  String? endpoint;

  StreamSubscription? hwSubscription;
  RxList audioInputs = [].obs;
  RxList videoInputs = [].obs;

  RxBool enableAudio = true.obs;
  RxBool enableVideo = false.obs;
  Rx<LocalAudioTrack?> audioTrack = Rx(null);
  Rx<LocalVideoTrack?> videoTrack = Rx(null);
  Rx<MediaDevice?> videoDevice = Rx(null);
  Rx<MediaDevice?> audioDevice = Rx(null);

  late Room room;
  late EventsListener<RoomEvent> listener;

  RxList<ParticipantTrack> participantTracks = RxList.empty(growable: true);
  Rx<ParticipantTrack?> focusTrack = Rx(null);

  Future<void> checkPermissions() async {
    if (lkPlatformIs(PlatformType.macOS) || lkPlatformIs(PlatformType.linux)) {
      return;
    }

    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
  }

  void setCall(Call call, Channel related) {
    current.value = call;
    channel.value = related;
  }

  Future<(String, String)> getRoomToken() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw Exception('unauthorized');

    final client = auth.configureClient('messaging');

    final resp = await client.post(
      '/channels/global/${channel.value!.alias}/calls/ongoing/token',
      {},
    );
    if (resp.statusCode == 200) {
      token = resp.body['token'];
      endpoint = 'wss://${resp.body['endpoint']}';
      return (token!, endpoint!);
    } else {
      throw Exception(resp.bodyString);
    }
  }

  void initHardware() {
    if (isReady.value) {
      return;
    } else {
      isReady.value = true;
    }

    hwSubscription = Hardware.instance.onDeviceChange.stream.listen(
      revertDevices,
    );
    Hardware.instance.enumerateDevices().then(revertDevices);
  }

  void initRoom() {
    initHardware();
    room = Room();
    listener = room.createListener();
    WakelockPlus.enable();
  }

  void joinRoom(String url, String token) async {
    if (isMounted.value) {
      return;
    } else {
      isMounted.value = true;
    }

    try {
      await room.connect(
        url,
        token,
        roomOptions: const RoomOptions(
          dynacast: true,
          adaptiveStream: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'call_voice',
            stream: 'call_stream',
          ),
          defaultVideoPublishOptions: VideoPublishOptions(
            name: 'call_video',
            stream: 'call_stream',
            simulcast: true,
            backupVideoCodec: BackupVideoCodec(enabled: true),
          ),
          defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
            params: VideoParametersPresets.h1080_169,
          ),
        ),
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(track: audioTrack.value),
          camera: TrackOption(track: videoTrack.value),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void autoPublish() async {
    try {
      if (enableVideo.value) {
        await room.localParticipant?.setCameraEnabled(true);
      }
      if (enableAudio.value) {
        await room.localParticipant?.setMicrophoneEnabled(true);
      }
    } catch (error) {
      rethrow;
    }
  }

  void onRoomDidUpdate() => sortParticipants();

  void setupRoom() {
    if(isInitialized.value) return;

    sortParticipants();
    room.addListener(onRoomDidUpdate);
    WidgetsBindingCompatible.instance?.addPostFrameCallback(
      (_) => autoPublish(),
    );

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }

    isInitialized.value = true;
  }

  void setupRoomListeners({
    required Function(DisconnectReason?) onDisconnected,
  }) {
    listener
      ..on<RoomDisconnectedEvent>((event) async {
        onDisconnected(event.reason);
      })
      ..on<ParticipantEvent>((event) => sortParticipants())
      ..on<LocalTrackPublishedEvent>((_) => sortParticipants())
      ..on<LocalTrackUnpublishedEvent>((_) => sortParticipants())
      ..on<TrackSubscribedEvent>((_) => sortParticipants())
      ..on<TrackUnsubscribedEvent>((_) => sortParticipants())
      ..on<ParticipantNameUpdatedEvent>((event) {
        sortParticipants();
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

    final newTracks = List<ParticipantTrack>.empty(growable: true);

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
      return a.participant.joinedAt.millisecondsSinceEpoch -
          b.participant.joinedAt.millisecondsSinceEpoch;
    });

    newTracks.addAll(mediaTrackList);

    if (room.localParticipant != null) {
      ParticipantTrack localTrack = ParticipantTrack(
        participant: room.localParticipant!,
        videoTrack: null,
        isScreenShare: false,
      );

      final localParticipantTracks =
          room.localParticipant?.videoTrackPublications;
      if (localParticipantTracks != null) {
        for (var t in localParticipantTracks) {
          localTrack.videoTrack = t.track;
          localTrack.isScreenShare = t.isScreenShare;
        }
      }

      newTracks.add(localTrack);
    }

    participantTracks.value = newTracks;

    if (focusTrack.value != null) {
      final idx = participantTracks.indexWhere(
          (x) => x.participant.sid == focusTrack.value!.participant.sid);
      if (idx == -1) {
        focusTrack.value = null;
      }
    }

    if (focusTrack.value == null) {
      focusTrack.value = participantTracks.firstOrNull;
    } else {
      final idx = participantTracks.indexWhere(
        (x) => focusTrack.value!.participant.sid == x.participant.sid,
      );
      if (idx > -1) {
        focusTrack.value = participantTracks[idx];
      }
    }
  }

  void revertDevices(List<MediaDevice> devices) async {
    audioInputs.clear();
    audioInputs.addAll(devices.where((d) => d.kind == 'audioinput'));
    videoInputs.clear();
    videoInputs.addAll(devices.where((d) => d.kind == 'videoinput'));

    if (audioInputs.isNotEmpty) {
      if (audioDevice.value == null && enableAudio.value) {
        audioDevice.value = audioInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalAudioTrack();
        });
      }
    }

    if (videoInputs.isNotEmpty) {
      if (videoDevice.value == null && enableVideo.value) {
        videoDevice.value = videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await changeLocalVideoTrack();
        });
      }
    }
  }

  Future<void> setEnableVideo(value) async {
    enableVideo.value = value;
    if (!enableVideo.value) {
      await videoTrack.value?.stop();
      videoTrack.value = null;
    } else {
      await changeLocalVideoTrack();
    }
  }

  Future<void> setEnableAudio(value) async {
    enableAudio.value = value;
    if (!enableAudio.value) {
      await audioTrack.value?.stop();
      audioTrack.value = null;
    } else {
      await changeLocalAudioTrack();
    }
  }

  Future<void> changeLocalAudioTrack() async {
    if (audioTrack.value != null) {
      await audioTrack.value!.stop();
      audioTrack.value = null;
    }

    if (audioDevice.value != null) {
      audioTrack.value = await LocalAudioTrack.create(
        AudioCaptureOptions(
          deviceId: audioDevice.value!.deviceId,
        ),
      );
      await audioTrack.value!.start();
    }
  }

  Future<void> changeLocalVideoTrack() async {
    if (videoTrack.value != null) {
      await videoTrack.value!.stop();
      videoTrack.value = null;
    }

    if (videoDevice.value != null) {
      videoTrack.value = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: videoDevice.value!.deviceId,
          params: VideoParametersPresets.h1080_169,
        ),
      );
      await videoTrack.value!.start();
    }
  }

  void changeFocusTrack(ParticipantTrack track) {
    focusTrack.value = track;
  }

  Future gotoScreen(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const CallScreen()),
    );
  }

  void deactivateHardware() {
    hwSubscription?.cancel();
  }

  void disposeRoom() {
    isMounted.value = false;
    isInitialized.value = false;
    current.value = null;
    channel.value = null;
    room.removeListener(onRoomDidUpdate);
    room.disconnect();
    room.dispose();
    listener.dispose();
    WakelockPlus.disable();
  }

  void disposeHardware() {
    isReady.value = false;
    audioTrack.value?.stop();
    audioTrack.value = null;
    videoTrack.value?.stop();
    videoTrack.value = null;
  }
}
