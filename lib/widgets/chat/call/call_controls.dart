import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/content/call.dart';

class ControlsWidget extends StatefulWidget {
  final Room room;
  final LocalParticipant participant;

  const ControlsWidget(
    this.room,
    this.participant, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget> {
  CameraPosition position = CameraPosition.front;

  List<MediaDevice>? _audioInputs;
  List<MediaDevice>? _audioOutputs;
  List<MediaDevice>? _videoInputs;

  StreamSubscription? _subscription;

  bool _speakerphoneOn = false;

  @override
  void initState() {
    super.initState();
    participant.addListener(onChange);
    _subscription = Hardware.instance.onDeviceChange.stream
        .listen((List<MediaDevice> devices) {
      revertDevices(devices);
    });
    Hardware.instance.enumerateDevices().then(revertDevices);
    _speakerphoneOn = Hardware.instance.speakerOn ?? false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    participant.removeListener(onChange);
    super.dispose();
  }

  LocalParticipant get participant => widget.participant;

  void revertDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    setState(() {});
  }

  void onChange() => setState(() {});

  bool get isMuted => participant.isMuted;

  Future<bool?> showDisconnectDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('callDisconnect'.tr),
        content: Text('callDisconnectCaption'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void disconnect() async {
    if (await showDisconnectDialog() != true) return;

    final ChatCallProvider provider = Get.find();
    if (provider.current.value != null) {
      provider.disposeRoom();
      Navigator.pop(context);
    }
  }

  void disableAudio() async {
    await participant.setMicrophoneEnabled(false);
  }

  void enableAudio() async {
    await participant.setMicrophoneEnabled(true);
  }

  void disableVideo() async {
    await participant.setCameraEnabled(false);
  }

  void enableVideo() async {
    await participant.setCameraEnabled(true);
  }

  void selectAudioOutput(MediaDevice device) async {
    await widget.room.setAudioOutputDevice(device);
    setState(() {});
  }

  void selectAudioInput(MediaDevice device) async {
    await widget.room.setAudioInputDevice(device);
    setState(() {});
  }

  void selectVideoInput(MediaDevice device) async {
    await widget.room.setVideoInputDevice(device);
    setState(() {});
  }

  void setSpeakerphoneOn() {
    _speakerphoneOn = !_speakerphoneOn;
    Hardware.instance.setSpeakerphoneOn(_speakerphoneOn);
    setState(() {});
  }

  void toggleCamera() async {
    final track = participant.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;

    try {
      final newPosition = position.switched();
      await track.setCameraPosition(newPosition);
      setState(() {
        position = newPosition;
      });
    } catch (error) {
      return;
    }
  }

  void enableScreenShare() async {
    if (lkPlatformIsDesktop()) {
      try {
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        if (source == null) {
          return;
        }
        var track = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: source.id,
            maxFrameRate: 15.0,
          ),
        );
        await participant.publishVideoTrack(track);
      } catch (e) {
        final message = e.toString();
        context.showErrorDialog(message);
      }
      return;
    }
    if (lkPlatformIs(PlatformType.android)) {
      requestBackgroundPermission([bool isRetry = false]) async {
        try {
          bool hasPermissions = await FlutterBackground.hasPermissions;
          if (!isRetry) {
            const androidConfig = FlutterBackgroundAndroidConfig(
              notificationTitle: 'Screen Sharing',
              notificationText: 'Solar Messager is sharing your screen',
              notificationImportance: AndroidNotificationImportance.Default,
              notificationIcon:
                  AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
            );
            hasPermissions = await FlutterBackground.initialize(
                androidConfig: androidConfig);
          }
          if (hasPermissions &&
              !FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
        } catch (e) {
          if (!isRetry) {
            return await Future<void>.delayed(const Duration(seconds: 1),
                () => requestBackgroundPermission(true));
          }
        }
      }

      await requestBackgroundPermission();
    }
    if (lkPlatformIs(PlatformType.iOS)) {
      var track = await LocalVideoTrack.createScreenShareTrack(
        const ScreenShareCaptureOptions(
          useiOSBroadcastExtension: true,
          maxFrameRate: 30.0,
        ),
      );
      await participant.publishVideoTrack(track);
      return;
    }

    if (lkPlatformIsWebMobile()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Screen share is not supported mobile platform.'),
      ));
      return;
    }

    await participant.setScreenShareEnabled(true, captureScreenAudio: true);
  }

  void disableScreenShare() async {
    await participant.setScreenShareEnabled(false);
    if (lkPlatformIs(PlatformType.android)) {
      // Android specific
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          IconButton(
            icon: Transform.flip(
                flipX: true, child: const Icon(Icons.exit_to_app)),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: disconnect,
          ),
          if (participant.isMicrophoneEnabled())
            if (lkPlatformIs(PlatformType.android))
              IconButton(
                onPressed: disableAudio,
                icon: const Icon(Icons.mic),
                color: Theme.of(context).colorScheme.onSurface,
                tooltip: 'callMicrophoneOff'.tr,
              )
            else
              PopupMenuButton<MediaDevice>(
                icon: const Icon(Icons.settings_voice),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<MediaDevice>(
                      value: null,
                      onTap: isMuted ? enableAudio : disableAudio,
                      child: ListTile(
                        leading: const Icon(Icons.mic_off),
                        title: Text('callMicrophoneOn'.tr),
                      ),
                    ),
                    if (_audioInputs != null)
                      ..._audioInputs!.map((device) {
                        return PopupMenuItem<MediaDevice>(
                          value: device,
                          child: ListTile(
                            leading: (device.deviceId ==
                                    widget.room.selectedAudioInputDeviceId)
                                ? const Icon(Icons.check_box_outlined)
                                : const Icon(Icons.check_box_outline_blank),
                            title: Text(device.label),
                          ),
                          onTap: () => selectAudioInput(device),
                        );
                      })
                  ];
                },
              )
          else
            IconButton(
              onPressed: enableAudio,
              icon: const Icon(Icons.mic_off),
              color: Theme.of(context).colorScheme.onSurface,
              tooltip: 'callMicrophoneOn'.tr,
            ),
          if (participant.isCameraEnabled())
            PopupMenuButton<MediaDevice>(
              icon: const Icon(Icons.videocam_sharp),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<MediaDevice>(
                    value: null,
                    onTap: disableVideo,
                    child: ListTile(
                      leading: const Icon(Icons.videocam_off),
                      title: Text('callCameraOff'.tr),
                    ),
                  ),
                  if (_videoInputs != null)
                    ..._videoInputs!.map((device) {
                      return PopupMenuItem<MediaDevice>(
                        value: device,
                        child: ListTile(
                          leading: (device.deviceId ==
                                  widget.room.selectedVideoInputDeviceId)
                              ? const Icon(Icons.check_box_outlined)
                              : const Icon(Icons.check_box_outline_blank),
                          title: Text(device.label),
                        ),
                        onTap: () => selectVideoInput(device),
                      );
                    })
                ];
              },
            )
          else
            IconButton(
              onPressed: enableVideo,
              icon: const Icon(Icons.videocam_off),
              color: Theme.of(context).colorScheme.onSurface,
              tooltip: 'callCameraOn'.tr,
            ),
          IconButton(
            icon: Icon(position == CameraPosition.back
                ? Icons.video_camera_back
                : Icons.video_camera_front),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () => toggleCamera(),
            tooltip: 'callVideoFlip'.tr,
          ),
          if (!lkPlatformIs(PlatformType.iOS))
            PopupMenuButton<MediaDevice>(
              icon: const Icon(Icons.volume_up),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<MediaDevice>(
                    value: null,
                    child: ListTile(
                      leading: const Icon(Icons.speaker),
                      title: Text('callSpeakerSelect'.tr),
                    ),
                  ),
                  if (_audioOutputs != null)
                    ..._audioOutputs!.map((device) {
                      return PopupMenuItem<MediaDevice>(
                        value: device,
                        child: ListTile(
                          leading: (device.deviceId ==
                                  widget.room.selectedAudioOutputDeviceId)
                              ? const Icon(Icons.check_box_outlined)
                              : const Icon(Icons.check_box_outline_blank),
                          title: Text(device.label),
                        ),
                        onTap: () => selectAudioOutput(device),
                      );
                    })
                ];
              },
            ),
          if (!kIsWeb && lkPlatformIs(PlatformType.iOS))
            IconButton(
              onPressed: Hardware.instance.canSwitchSpeakerphone
                  ? setSpeakerphoneOn
                  : null,
              color: Theme.of(context).colorScheme.onSurface,
              icon: Icon(
                _speakerphoneOn ? Icons.volume_up : Icons.volume_down,
              ),
              tooltip: 'callSpeakerphoneToggle'.tr,
            ),
          if (participant.isScreenShareEnabled())
            IconButton(
              icon: const Icon(Icons.monitor_outlined),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => disableScreenShare(),
              tooltip: 'callScreenOff'.tr,
            )
          else
            IconButton(
              icon: const Icon(Icons.monitor),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => enableScreenShare(),
              tooltip: 'callScreenOn'.tr,
            ),
        ],
      ),
    );
  }
}
