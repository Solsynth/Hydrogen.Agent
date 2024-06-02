import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/widgets/chat/call/call_controls.dart';
import 'package:solian/widgets/chat/call/call_participant.dart';
import 'package:solian/widgets/prev_page.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? timer;
  String currentDuration = '00:00:00';

  String parseDuration() {
    final ChatCallProvider provider = Get.find();
    if (provider.current.value == null) return '00:00:00';
    Duration duration =
        DateTime.now().difference(provider.current.value!.createdAt);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String formattedTime = "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes.remainder(60))}:"
        "${twoDigits(duration.inSeconds.remainder(60))}";

    return formattedTime;
  }

  void updateDuration() {
    setState(() {
      currentDuration = parseDuration();
    });
  }

  @override
  void initState() {
    Get.find<ChatCallProvider>().setupRoom();
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) => updateDuration());
  }

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider provider = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'call'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const TextSpan(text: "\n"),
              TextSpan(
                text: currentDuration,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          leading: const PrevPageButton(),
        ),
        body: SafeArea(
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
                                    provider
                                        .focusTrack.value?.participant.sid) {
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
      ),
    );
  }

  @override
  void deactivate() {
    timer?.cancel();
    timer = null;
    super.deactivate();
  }

  @override
  void activate() {
    timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateDuration(),
    );
    super.activate();
  }
}
