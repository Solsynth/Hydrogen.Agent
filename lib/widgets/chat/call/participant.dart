import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/call.dart';
import 'package:solian/widgets/chat/call/no_content.dart';
import 'package:solian/widgets/chat/call/participant_info.dart';
import 'package:solian/widgets/chat/call/participant_stats.dart';

abstract class ParticipantWidget extends StatefulWidget {
  static ParticipantWidget widgetFor(ParticipantTrack participantTrack, {bool showStatsLayer = false}) {
    if (participantTrack.participant is LocalParticipant) {
      return LocalParticipantWidget(participantTrack.participant as LocalParticipant, participantTrack.videoTrack,
          participantTrack.isScreenShare, showStatsLayer);
    } else if (participantTrack.participant is RemoteParticipant) {
      return RemoteParticipantWidget(participantTrack.participant as RemoteParticipant, participantTrack.videoTrack,
          participantTrack.isScreenShare, showStatsLayer);
    }
    throw UnimplementedError('Unknown participant type');
  }

  abstract final Participant participant;
  abstract final VideoTrack? videoTrack;
  abstract final bool isScreenShare;
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
  final bool isScreenShare;
  @override
  final bool showStatsLayer;

  const LocalParticipantWidget(
    this.participant,
    this.videoTrack,
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
  final bool isScreenShare;
  @override
  final bool showStatsLayer;

  const RemoteParticipantWidget(
    this.participant,
    this.videoTrack,
    this.isScreenShare,
    this.showStatsLayer, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _RemoteParticipantWidgetState();
}

abstract class _ParticipantWidgetState<T extends ParticipantWidget> extends State<T> {
  bool _visible = true;

  VideoTrack? get _activeVideoTrack;

  TrackPublication? get _videoPublication;

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
        _userinfoMetadata = Account.fromJson(jsonDecode(widget.participant.metadata!));
      }
    });
  }

  List<Widget> extraWidgets(bool isScreenShare) => [];

  @override
  Widget build(BuildContext ctx) {
    return Container(
      child: Stack(
        children: [
          // Video
          InkWell(
            onTap: () => setState(() => _visible = !_visible),
            child: _activeVideoTrack != null && !_activeVideoTrack!.muted
                ? VideoTrackRenderer(
                    _activeVideoTrack!,
                    fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  )
                : NoContentWidget(
                    userinfo: _userinfoMetadata,
                    isSpeaking: widget.participant.isSpeaking,
                  ),
          ),
          if (widget.showStatsLayer)
            Positioned(
              top: 30,
              right: 30,
              child: ParticipantStatsWidget(
                participant: widget.participant,
              ),
            ),
          // Bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...extraWidgets(widget.isScreenShare),
                ParticipantInfoWidget(
                  title: widget.participant.name.isNotEmpty
                      ? '${widget.participant.name} (${widget.participant.identity})'
                      : widget.participant.identity,
                  audioAvailable: _firstAudioPublication?.muted == false && _firstAudioPublication?.subscribed == true,
                  connectionQuality: widget.participant.connectionQuality,
                  isScreenShare: widget.isScreenShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalParticipantWidgetState extends _ParticipantWidgetState<LocalParticipantWidget> {
  @override
  LocalTrackPublication<LocalVideoTrack>? get _videoPublication =>
      widget.participant.videoTrackPublications.where((element) => element.sid == widget.videoTrack?.sid).firstOrNull;

  @override
  LocalTrackPublication<LocalAudioTrack>? get _firstAudioPublication =>
      widget.participant.audioTrackPublications.firstOrNull;

  @override
  VideoTrack? get _activeVideoTrack => widget.videoTrack;
}

class _RemoteParticipantWidgetState extends _ParticipantWidgetState<RemoteParticipantWidget> {
  @override
  RemoteTrackPublication<RemoteVideoTrack>? get _videoPublication =>
      widget.participant.videoTrackPublications.where((element) => element.sid == widget.videoTrack?.sid).firstOrNull;

  @override
  RemoteTrackPublication<RemoteAudioTrack>? get _firstAudioPublication =>
      widget.participant.audioTrackPublications.firstOrNull;

  @override
  VideoTrack? get _activeVideoTrack => widget.videoTrack;

  @override
  List<Widget> extraWidgets(bool isScreenShare) => [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Menu for RemoteTrackPublication<RemoteAudioTrack>
            if (_firstAudioPublication != null && !isScreenShare)
              RemoteTrackPublicationMenuWidget(
                pub: _firstAudioPublication!,
                icon: Icons.volume_up,
              ),
            if (_videoPublication != null)
              RemoteTrackPublicationMenuWidget(
                pub: _videoPublication!,
                icon: isScreenShare ? Icons.monitor : Icons.videocam,
              ),
            if (_videoPublication != null)
              RemoteTrackFPSMenuWidget(
                pub: _videoPublication!,
                icon: Icons.menu,
              ),
            if (_videoPublication != null)
              RemoteTrackQualityMenuWidget(
                pub: _videoPublication!,
                icon: Icons.monitor_outlined,
              ),
          ],
        ),
      ];
}

class RemoteTrackPublicationMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;

  const RemoteTrackPublicationMenuWidget({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: PopupMenuButton<Function>(
          tooltip: 'Subscribe menu',
          icon: Icon(icon,
              color: {
                TrackSubscriptionState.notAllowed: Colors.red,
                TrackSubscriptionState.unsubscribed: Colors.grey,
                TrackSubscriptionState.subscribed: Colors.green,
              }[pub.subscriptionState]),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
            if (pub.subscribed == false)
              PopupMenuItem(
                child: const Text('Subscribe'),
                value: () => pub.subscribe(),
              )
            else if (pub.subscribed == true)
              PopupMenuItem(
                child: const Text('Un-subscribe'),
                value: () => pub.unsubscribe(),
              ),
          ],
        ),
      );
}

class RemoteTrackFPSMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;

  const RemoteTrackFPSMenuWidget({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: PopupMenuButton<Function>(
          tooltip: 'Preferred FPS',
          icon: Icon(icon, color: Colors.white),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
            PopupMenuItem(
              child: const Text('30'),
              value: () => pub.setVideoFPS(30),
            ),
            PopupMenuItem(
              child: const Text('15'),
              value: () => pub.setVideoFPS(15),
            ),
            PopupMenuItem(
              child: const Text('8'),
              value: () => pub.setVideoFPS(8),
            ),
          ],
        ),
      );
}

class RemoteTrackQualityMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;

  const RemoteTrackQualityMenuWidget({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: PopupMenuButton<Function>(
          tooltip: 'Preferred Quality',
          icon: Icon(icon, color: Colors.white),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
            PopupMenuItem(
              child: const Text('HIGH'),
              value: () => pub.setVideoQuality(VideoQuality.HIGH),
            ),
            PopupMenuItem(
              child: const Text('MEDIUM'),
              value: () => pub.setVideoQuality(VideoQuality.MEDIUM),
            ),
            PopupMenuItem(
              child: const Text('LOW'),
              value: () => pub.setVideoQuality(VideoQuality.LOW),
            ),
          ],
        ),
      );
}
