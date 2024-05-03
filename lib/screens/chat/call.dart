import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/chat/call/call_controls.dart';
import 'package:solian/widgets/chat/call/participant.dart';
import 'package:solian/widgets/chat/call/participant_menu.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;

class ChatCall extends StatefulWidget {
  final Call call;

  const ChatCall({super.key, required this.call});

  @override
  State<ChatCall> createState() => _ChatCallState();
}

class _ChatCallState extends State<ChatCall> {
  bool _isHandled = false;

  late ChatProvider _chat;

  ChatCallInstance get _call => _chat.currentCall!;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.setCallShown(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    _chat = context.watch<ChatProvider>();
    if (!_isHandled) {
      _isHandled = true;
      if (_chat.handleCallJoin(widget.call, widget.call.channel)) {
        _chat.currentCall?.init();
      }
    }

    Widget content;
    if (_chat.currentCall == null) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      content = FutureBuilder(
        future: _call.exchangeToken(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: _call.focusTrack != null
                          ? InteractiveParticipantWidget(
                              isFixed: false,
                              participant: _call.focusTrack!,
                              onTap: () {},
                            )
                          : Container(),
                    ),
                  ),
                  if (_call.room.localParticipant != null)
                    ControlsWidget(
                      _call.room,
                      _call.room.localParticipant!,
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
                    itemCount: math.max(0, _call.participantTracks.length),
                    itemBuilder: (BuildContext context, int index) {
                      final track = _call.participantTracks[index];
                      if (track.participant.sid ==
                          _call.focusTrack?.participant.sid) {
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
                                  _call.focusTrack?.participant.sid) {
                                _call.changeFocusTrack(track);
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
        },
      );
    }

    return IndentScaffold(
      title: AppLocalizations.of(context)!.chatCall,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      hideDrawer: true,
      child: content,
    );
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _chat.setCallShown(false));
    super.deactivate();
  }
}

class InteractiveParticipantWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool isFixed;
  final ParticipantTrack participant;
  final Function() onTap;

  const InteractiveParticipantWidget({
    super.key,
    this.width,
    this.height,
    this.color,
    this.isFixed = false,
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        width: width,
        height: height,
        color: color,
        child: ParticipantWidget.widgetFor(participant, isFixed: isFixed),
      ),
      onTap: () => onTap(),
      onLongPress: () {
        if (participant.participant is LocalParticipant) return;
        showModalBottomSheet(
          context: context,
          builder: (context) => ParticipantMenu(
            participant: participant.participant as RemoteParticipant,
            videoTrack: participant.videoTrack,
            isScreenShare: participant.isScreenShare,
          ),
        );
      },
    );
  }
}
