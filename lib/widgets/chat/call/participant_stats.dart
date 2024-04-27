import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/models/call.dart';

class ParticipantStatsWidget extends StatefulWidget {
  const ParticipantStatsWidget({super.key, required this.participant});

  final Participant participant;

  @override
  State<StatefulWidget> createState() => _ParticipantStatsWidgetState();
}

class _ParticipantStatsWidgetState extends State<ParticipantStatsWidget> {
  List<EventsListener<TrackEvent>> listeners = [];
  ParticipantStatsType statsType = ParticipantStatsType.unknown;
  Map<String, String> stats = {};

  void _setUpListener(Track track) {
    var listener = track.createListener();
    listeners.add(listener);
    if (track is LocalVideoTrack) {
      statsType = ParticipantStatsType.localVideoSender;
      listener.on<VideoSenderStatsEvent>((event) {
        setState(() {
          stats['video tx'] = 'total sent ${event.currentBitrate.toInt()} kpbs';
          event.stats.forEach((key, value) {
            stats['layer-$key'] =
                '${value.frameWidth ?? 0}x${value.frameHeight ?? 0} ${value.framesPerSecond?.toDouble() ?? 0} fps, ${event.bitrateForLayers[key] ?? 0} kbps';
          });
          var firstStats = event.stats['f'] ?? event.stats['h'] ?? event.stats['q'];
          if (firstStats != null) {
            stats['encoder'] = firstStats.encoderImplementation ?? '';
            stats['video codec'] = '${firstStats.mimeType}, ${firstStats.clockRate}hz, pt: ${firstStats.payloadType}';
            stats['qualityLimitationReason'] = firstStats.qualityLimitationReason ?? '';
          }
        });
      });
    } else if (track is RemoteVideoTrack) {
      statsType = ParticipantStatsType.remoteVideoReceiver;
      listener.on<VideoReceiverStatsEvent>((event) {
        setState(() {
          stats['video rx'] = '${event.currentBitrate.toInt()} kpbs';
          stats['video codec'] = '${event.stats.mimeType}, ${event.stats.clockRate}hz, pt: ${event.stats.payloadType}';
          stats['video size'] =
              '${event.stats.frameWidth}x${event.stats.frameHeight} ${event.stats.framesPerSecond?.toDouble()}fps';
          stats['video jitter'] = '${event.stats.jitter} s';
          stats['video decoder'] = '${event.stats.decoderImplementation}';
          stats['video packets lost'] = '${event.stats.packetsLost}';
          stats['video packets received'] = '${event.stats.packetsReceived}';
          stats['video frames received'] = '${event.stats.framesReceived}';
          stats['video frames decoded'] = '${event.stats.framesDecoded}';
          stats['video frames dropped'] = '${event.stats.framesDropped}';
        });
      });
    } else if (track is LocalAudioTrack) {
      statsType = ParticipantStatsType.localAudioSender;
      listener.on<AudioSenderStatsEvent>((event) {
        setState(() {
          stats['audio tx'] = '${event.currentBitrate.toInt()} kpbs';
          stats['audio codec'] =
              '${event.stats.mimeType}, ${event.stats.clockRate}hz, ${event.stats.channels}ch, pt: ${event.stats.payloadType}';
        });
      });
    } else if (track is RemoteAudioTrack) {
      statsType = ParticipantStatsType.remoteAudioReceiver;
      listener.on<AudioReceiverStatsEvent>((event) {
        setState(() {
          stats['audio rx'] = '${event.currentBitrate.toInt()} kpbs';
          stats['audio codec'] =
              '${event.stats.mimeType}, ${event.stats.clockRate}hz, ${event.stats.channels}ch, pt: ${event.stats.payloadType}';
          stats['audio jitter'] = '${event.stats.jitter} s';
          stats['audio concealed samples'] = '${event.stats.concealedSamples} / ${event.stats.concealmentEvents}';
          stats['audio packets lost'] = '${event.stats.packetsLost}';
          stats['audio packets received'] = '${event.stats.packetsReceived}';
        });
      });
    }
  }

  onParticipantChanged() {
    for (var element in listeners) {
      element.dispose();
    }
    listeners.clear();
    for (var track in [...widget.participant.videoTrackPublications, ...widget.participant.audioTrackPublications]) {
      if (track.track != null) {
        _setUpListener(track.track!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(onParticipantChanged);
    onParticipantChanged();
  }

  @override
  void deactivate() {
    for (var element in listeners) {
      element.dispose();
    }
    widget.participant.removeListener(onParticipantChanged);
    super.deactivate();
  }

  num sendBitrate = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 8,
      ),
      child: Column(
        children: stats.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
      ),
    );
  }
}
