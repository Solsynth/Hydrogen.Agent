import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class ParticipantInfoWidget extends StatelessWidget {
  final String? title;
  final bool audioAvailable;
  final ConnectionQuality connectionQuality;
  final bool isScreenShare;

  const ParticipantInfoWidget({
    super.key,
    this.title,
    this.audioAvailable = true,
    this.connectionQuality = ConnectionQuality.unknown,
    this.isScreenShare = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        padding: const EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Flexible(
                child: Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            isScreenShare
                ? const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.monitor,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Icon(
                      audioAvailable ? Icons.mic : Icons.mic_off,
                      color: audioAvailable ? Colors.white : Colors.red,
                      size: 16,
                    ),
                  ),
            if (connectionQuality != ConnectionQuality.unknown)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  connectionQuality == ConnectionQuality.poor
                      ? Icons.wifi_off_outlined
                      : Icons.wifi,
                  color: {
                    ConnectionQuality.excellent: Colors.green,
                    ConnectionQuality.good: Colors.orange,
                    ConnectionQuality.poor: Colors.red,
                  }[connectionQuality],
                  size: 16,
                ),
              ),
          ],
        ),
      );
}
