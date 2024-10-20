import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/call.dart';

class ChatCallPrejoinPopup extends StatefulWidget {
  final Call ongoingCall;
  final Channel channel;
  final Function onJoin;

  const ChatCallPrejoinPopup({
    super.key,
    required this.ongoingCall,
    required this.channel,
    required this.onJoin,
  });

  @override
  State<ChatCallPrejoinPopup> createState() => _ChatCallPrejoinPopupState();
}

class _ChatCallPrejoinPopupState extends State<ChatCallPrejoinPopup> {
  bool _isBusy = false;

  void _performJoin() async {
    final AuthProvider auth = Get.find();
    final ChatCallProvider call = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    call.setCall(widget.ongoingCall, widget.channel);
    call.isBusy.value = true;

    try {
      final resp = await call.getRoomToken();
      final token = resp.$1;
      final endpoint = resp.$2;

      call.initRoom();
      call.setupRoomListeners(
        onDisconnected: (reason) {
          context.showSnackbar(
            'callDisconnected'.trParams({'reason': reason.toString()}),
          );
        },
      );

      call.joinRoom(endpoint, token);

      Navigator.pop(context);
    } catch (e) {
      context.showErrorDialog(e);
    }

    widget.onJoin();
    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    final ChatCallProvider call = Get.find();
    call.checkPermissions().then((_) {
      call.initHardware();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider provider = Get.find();

    return Obx(
      () => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('callMicrophone'.tr),
                  Switch(
                    value: provider.enableAudio.value,
                    onChanged: null,
                  ),
                ],
              ).paddingOnly(bottom: 5),
              DropdownButtonHideUnderline(
                child: DropdownButton2<MediaDevice>(
                  isExpanded: true,
                  disabledHint: Text('callMicrophoneDisabled'.tr),
                  hint: Text('callMicrophoneSelect'.tr),
                  items: provider.enableAudio.value
                      ? provider.audioInputs
                          .map(
                            (item) => DropdownMenuItem<MediaDevice>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList()
                          .cast<DropdownMenuItem<MediaDevice>>()
                      : [],
                  value: provider.audioDevice.value,
                  onChanged: (MediaDevice? value) async {
                    if (value != null) {
                      provider.audioDevice.value = value;
                      await provider.changeLocalAudioTrack();
                    }
                  },
                  buttonStyleData: const ButtonStyleData(
                    height: 40,
                    width: 320,
                  ),
                ),
              ).paddingOnly(bottom: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('callCamera'.tr),
                  Switch(
                    value: provider.enableVideo.value,
                    onChanged: (value) => provider.enableVideo.value = value,
                  ),
                ],
              ).paddingOnly(bottom: 5),
              DropdownButtonHideUnderline(
                child: DropdownButton2<MediaDevice>(
                  isExpanded: true,
                  disabledHint: Text('callCameraDisabled'.tr),
                  hint: Text('callCameraSelect'.tr),
                  items: provider.enableVideo.value
                      ? provider.videoInputs
                          .map(
                            (item) => DropdownMenuItem<MediaDevice>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList()
                          .cast<DropdownMenuItem<MediaDevice>>()
                      : [],
                  value: provider.videoDevice.value,
                  onChanged: (MediaDevice? value) async {
                    if (value != null) {
                      provider.videoDevice.value = value;
                      await provider.changeLocalVideoTrack();
                    }
                  },
                  buttonStyleData: const ButtonStyleData(
                    height: 40,
                    width: 320,
                  ),
                ),
              ).paddingOnly(bottom: 25),
              if (_isBusy)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(320, 56),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: _isBusy ? null : _performJoin,
                  child: Text('callJoin'.tr),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Get.find<ChatCallProvider>()
      ..deactivateHardware()
      ..disposeHardware();
    super.dispose();
  }
}
