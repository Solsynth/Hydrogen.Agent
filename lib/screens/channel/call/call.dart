import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/widgets/chat/call/call_controls.dart';
import 'package:solian/widgets/chat/call/call_participant.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    Get.find<ChatCallProvider>().setupRoom();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider provider = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Obx(
          () => Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: provider.focusTrack.value != null
                          ? InteractiveParticipantWidget(
                              isFixed: false,
                              participant: provider.focusTrack.value!,
                              onTap: () {},
                            )
                          : const SizedBox(),
                    ),
                  ),
                  if (provider.room.localParticipant != null)
                    ControlsWidget(
                      provider.room,
                      provider.room.localParticipant!,
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SizedBox(
                  height: 128,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.max(0, provider.participantTracks.length),
                    itemBuilder: (BuildContext context, int index) {
                      final track = provider.participantTracks[index];
                      if (track.participant.sid ==
                          provider.focusTrack.value?.participant.sid) {
                        return Container();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8, left: 8),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          child: InteractiveParticipantWidget(
                            isFixed: true,
                            width: 120,
                            height: 120,
                            color: Theme.of(context).cardColor,
                            participant: track,
                            onTap: () {
                              if (track.participant.sid !=
                                  provider.focusTrack.value?.participant.sid) {
                                provider.changeFocusTrack(track);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
