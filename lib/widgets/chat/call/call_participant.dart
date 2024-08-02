import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/call.dart';
import 'package:solian/widgets/chat/call/call_no_content.dart';
import 'package:solian/widgets/chat/call/call_participant_info.dart';
import 'package:solian/widgets/chat/call/call_participant_menu.dart';
import 'package:solian/widgets/chat/call/call_participant_stats.dart';

abstract class ParticipantWidget extends StatefulWidget {
  static ParticipantWidget widgetFor(ParticipantTrack participantTrack,
      {bool isFixed = false, bool showStatsLayer = false}) {
    if (participantTrack.participant is LocalParticipant) {
      return LocalParticipantWidget(
        participantTrack.participant as LocalParticipant,
        participantTrack.videoTrack,
        isFixed,
        participantTrack.isScreenShare,
        showStatsLayer,
      );
    } else if (participantTrack.participant is RemoteParticipant) {
      return RemoteParticipantWidget(
        participantTrack.participant as RemoteParticipant,
        participantTrack.videoTrack,
        isFixed,
        participantTrack.isScreenShare,
        showStatsLayer,
      );
    }
    throw UnimplementedError('Unknown participant type');
  }

  abstract final Participant participant;
  abstract final VideoTrack? videoTrack;
  abstract final bool isScreenShare;
  abstract final bool isFixed;
  abstract final bool showStatsLayer;
  final VideoQuality quality;

  const ParticipantWidget({
    super.key,
    this.quality = VideoQuality.MEDIUM,
  });
}

class LocalParticipantWidget extends ParticipantWidget {
  @override
  final LocalParticipant participant;
  @override
  final VideoTrack? videoTrack;
  @override
  final bool isFixed;
  @override
  final bool isScreenShare;
  @override
  final bool showStatsLayer;

  const LocalParticipantWidget(
    this.participant,
    this.videoTrack,
    this.isFixed,
    this.isScreenShare,
    this.showStatsLayer, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _LocalParticipantWidgetState();
}

class RemoteParticipantWidget extends ParticipantWidget {
  @override
  final RemoteParticipant participant;
  @override
  final VideoTrack? videoTrack;
  @override
  final bool isFixed;
  @override
  final bool isScreenShare;
  @override
  final bool showStatsLayer;

  const RemoteParticipantWidget(
    this.participant,
    this.videoTrack,
    this.isFixed,
    this.isScreenShare,
    this.showStatsLayer, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _RemoteParticipantWidgetState();
}

abstract class _ParticipantWidgetState<T extends ParticipantWidget>
    extends State<T> {
  VideoTrack? get _activeVideoTrack;

  TrackPublication? get _firstAudioPublication;

  Account? _userinfoMetadata;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(onParticipantChanged);
    onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    oldWidget.participant.removeListener(onParticipantChanged);
    widget.participant.addListener(onParticipantChanged);
    onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  void onParticipantChanged() {
    setState(() {
      if (widget.participant.metadata != null) {
        _userinfoMetadata =
            Account.fromJson(jsonDecode(widget.participant.metadata!));
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return Stack(
      children: [
        _activeVideoTrack != null && !_activeVideoTrack!.muted
            ? VideoTrackRenderer(
                _activeVideoTrack!,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              )
            : NoContentWidget(
                userinfo: _userinfoMetadata,
                isFixed: widget.isFixed,
                isSpeaking: widget.participant.isSpeaking,
              ),
        if (widget.showStatsLayer)
          Positioned(
            top: 30,
            right: 30,
            child: ParticipantStatsWidget(participant: widget.participant),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ParticipantInfoWidget(
                title: widget.participant.name.isNotEmpty
                    ? widget.participant.name
                    : widget.participant.identity,
                audioAvailable: _firstAudioPublication?.muted == false &&
                    _firstAudioPublication?.subscribed == true,
                connectionQuality: widget.participant.connectionQuality,
                isScreenShare: widget.isScreenShare,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalParticipantWidgetState
    extends _ParticipantWidgetState<LocalParticipantWidget> {
  @override
  LocalTrackPublication<LocalAudioTrack>? get _firstAudioPublication =>
      widget.participant.audioTrackPublications.firstOrNull;

  @override
  VideoTrack? get _activeVideoTrack => widget.videoTrack;
}

class _RemoteParticipantWidgetState
    extends _ParticipantWidgetState<RemoteParticipantWidget> {
  @override
  RemoteTrackPublication<RemoteAudioTrack>? get _firstAudioPublication =>
      widget.participant.audioTrackPublications.firstOrNull;

  @override
  VideoTrack? get _activeVideoTrack => widget.videoTrack;
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
    return GestureDetector(
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
