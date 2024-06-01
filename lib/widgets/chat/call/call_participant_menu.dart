import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

class ParticipantMenu extends StatefulWidget {
  final RemoteParticipant participant;
  final VideoTrack? videoTrack;
  final bool isScreenShare;
  final bool showStatsLayer;

  const ParticipantMenu({
    super.key,
    required this.participant,
    this.videoTrack,
    this.isScreenShare = false,
    this.showStatsLayer = false,
  });

  @override
  State<ParticipantMenu> createState() => _ParticipantMenuState();
}

class _ParticipantMenuState extends State<ParticipantMenu> {
  RemoteTrackPublication<RemoteVideoTrack>? get _videoPublication =>
      widget.participant.videoTrackPublications
          .where((element) => element.sid == widget.videoTrack?.sid)
          .firstOrNull;

  RemoteTrackPublication<RemoteAudioTrack>? get _firstAudioPublication =>
      widget.participant.audioTrackPublications.firstOrNull;

  void tookAction() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.only(left: 8, right: 8, top: 20, bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            child: Text(
              'callParticipantAction'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (_firstAudioPublication != null && !widget.isScreenShare)
                ListTile(
                  leading: Icon(
                    Icons.volume_up,
                    color: {
                      TrackSubscriptionState.notAllowed:
                          Theme.of(context).colorScheme.error,
                      TrackSubscriptionState.unsubscribed: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      TrackSubscriptionState.subscribed:
                          Theme.of(context).colorScheme.primary,
                    }[_firstAudioPublication!.subscriptionState],
                  ),
                  title: Text(
                    _firstAudioPublication!.subscribed
                        ? 'callParticipantMicrophoneOff'.tr
                        : 'callParticipantMicrophoneOn'.tr,
                  ),
                  onTap: () {
                    if (_firstAudioPublication!.subscribed) {
                      _firstAudioPublication!.unsubscribe();
                    } else {
                      _firstAudioPublication!.subscribe();
                    }
                    tookAction();
                  },
                ),
              if (_videoPublication != null)
                ListTile(
                  leading: Icon(
                    widget.isScreenShare ? Icons.monitor : Icons.videocam,
                    color: {
                      TrackSubscriptionState.notAllowed:
                          Theme.of(context).colorScheme.error,
                      TrackSubscriptionState.unsubscribed: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      TrackSubscriptionState.subscribed:
                          Theme.of(context).colorScheme.primary,
                    }[_videoPublication!.subscriptionState],
                  ),
                  title: Text(
                    _videoPublication!.subscribed
                        ? 'callParticipantVideoOff'.tr
                        : 'callParticipantVideoOn'.tr,
                  ),
                  onTap: () {
                    if (_videoPublication!.subscribed) {
                      _videoPublication!.unsubscribe();
                    } else {
                      _videoPublication!.subscribe();
                    }
                    tookAction();
                  },
                ),
              if (_videoPublication != null) const Divider(thickness: 0.3),
              if (_videoPublication != null)
                ...[30, 15, 8].map(
                  (x) => ListTile(
                    leading: Icon(
                      _videoPublication?.fps == x
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                    ),
                    title: Text('Set preferred frame-per-second to $x'),
                    onTap: () {
                      _videoPublication!.setVideoFPS(x);
                      tookAction();
                    },
                  ),
                ),
              if (_videoPublication != null) const Divider(thickness: 0.3),
              if (_videoPublication != null)
                ...[
                  ('High', VideoQuality.HIGH),
                  ('Medium', VideoQuality.MEDIUM),
                  ('Low', VideoQuality.LOW),
                ].map(
                  (x) => ListTile(
                    leading: Icon(
                      _videoPublication?.videoQuality == x.$2
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                    ),
                    title: Text('Set preferred quality to ${x.$1}'),
                    onTap: () {
                      _videoPublication!.setVideoQuality(x.$2);
                      tookAction();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
