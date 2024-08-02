import 'dart:async';
import 'dart:math' as math;

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/call.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/chat/call/call_controls.dart';
import 'package:solian/widgets/chat/call/call_participant.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  Timer? _timer;
  String _currentDuration = '00:00:00';

  int _layoutMode = 0;

  bool _showControls = true;
  CancelableOperation? _hideControlsOperation;

  late final AnimationController _controlsAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _controlsAnimation = CurvedAnimation(
    parent: _controlsAnimationController,
    curve: Curves.fastOutSlowIn,
  );

  String _parseDuration() {
    final ChatCallProvider provider = Get.find();
    if (provider.current.value == null) return '00:00:00';
    Duration duration =
        DateTime.now().difference(provider.current.value!.createdAt);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String formattedTime = '${twoDigits(duration.inHours)}:'
        '${twoDigits(duration.inMinutes.remainder(60))}:'
        '${twoDigits(duration.inSeconds.remainder(60))}';

    return formattedTime;
  }

  void _updateDuration() {
    setState(() {
      _currentDuration = _parseDuration();
    });
  }

  void _switchLayout() {
    if (_layoutMode < 1) {
      setState(() => _layoutMode++);
    } else {
      setState(() => _layoutMode = 0);
    }
  }

  void _toggleControls() {
    if (_showControls) {
      setState(() => _showControls = false);
      _controlsAnimationController.animateTo(0);
      _hideControlsOperation?.cancel();
    } else {
      setState(() => _showControls = true);
      _controlsAnimationController.animateTo(1);
      _planAutoHideControls();
    }
  }

  void _planAutoHideControls() {
    _hideControlsOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_showControls) _toggleControls();
      }),
    );
  }

  Widget _buildListLayout() {
    final ChatCallProvider call = Get.find();
    return Stack(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: call.focusTrack.value != null
              ? InteractiveParticipantWidget(
                  isFixed: false,
                  participant: call.focusTrack.value!,
                  onTap: () {},
                )
              : const SizedBox(),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: math.max(0, call.participantTracks.length),
              itemBuilder: (BuildContext context, int index) {
                final track = call.participantTracks[index];
                if (track.participant.sid ==
                    call.focusTrack.value?.participant.sid) {
                  return Container();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: InteractiveParticipantWidget(
                      isFixed: true,
                      width: 120,
                      height: 120,
                      color: Theme.of(context).cardColor,
                      participant: track,
                      onTap: () {
                        if (track.participant.sid !=
                            call.focusTrack.value?.participant.sid) {
                          call.changeFocusTrack(track);
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
    );
  }

  Widget _buildGridLayout() {
    final ChatCallProvider call = Get.find();
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;

        int columns = (math.sqrt(call.participantTracks.length)).ceil();
        int rows = (call.participantTracks.length / columns).ceil();

        double tileWidth = screenWidth / columns;
        double tileHeight = screenHeight / rows;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: tileWidth / tileHeight,
          ),
          itemCount: math.max(0, call.participantTracks.length),
          itemBuilder: (BuildContext context, int index) {
            final track = call.participantTracks[index];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: InteractiveParticipantWidget(
                  isFixed: true,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  participant: track,
                  onTap: () {
                    if (track.participant.sid !=
                        call.focusTrack.value?.participant.sid) {
                      call.changeFocusTrack(track);
                    }
                  },
                ),
              ),
            );
          },
        );
      }
    );
  }

  @override
  void initState() {
    Get.find<ChatCallProvider>().setupRoom();
    super.initState();

    _updateDuration();
    _planAutoHideControls();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDuration(),
    );
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider provider = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          centerTitle: true,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: 'call'.tr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const TextSpan(text: '\n'),
              TextSpan(
                text: _currentDuration,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Obx(
              () => Column(
                children: [
                  SizeTransition(
                    sizeFactor: _controlsAnimation,
                    axis: Axis.vertical,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 64,
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          IconButton(
                            icon: _layoutMode == 0
                                ? const Icon(Icons.view_list)
                                : const Icon(Icons.grid_view),
                            onPressed: () {
                              _switchLayout();
                            },
                          ),
                        ],
                      ).paddingSymmetric(horizontal: 10),
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        switch (_layoutMode) {
                          case 1:
                            return _buildGridLayout();
                          default:
                            return _buildListLayout();
                        }
                      },
                    ),
                  ),
                  if (provider.room.localParticipant != null)
                    SizeTransition(
                      sizeFactor: _controlsAnimation,
                      axis: Axis.vertical,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ControlsWidget(
                          provider.room,
                          provider.room.localParticipant!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onTap: () {
              _toggleControls();
            },
          ),
        ),
      ),
    );
  }

  @override
  void deactivate() {
    _timer?.cancel();
    _timer = null;
    super.deactivate();
  }

  @override
  void activate() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDuration(),
    );
    super.activate();
  }
}
