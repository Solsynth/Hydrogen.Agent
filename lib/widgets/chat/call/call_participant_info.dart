import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            const SizedBox(width: 5),
            isScreenShare
                ? const Icon(
                    Icons.monitor,
                    color: Colors.white,
                    size: 16,
                  )
                : Icon(
                    audioAvailable ? Icons.mic : Icons.mic_off,
                    color: audioAvailable ? Colors.white : Colors.red,
                    size: 16,
                  ),
            const SizedBox(width: 3),
            if (connectionQuality != ConnectionQuality.unknown)
              Icon(
                {
                  ConnectionQuality.excellent: Icons.signal_cellular_alt,
                  ConnectionQuality.good: Icons.signal_cellular_alt_2_bar,
                  ConnectionQuality.poor: Icons.signal_cellular_alt_1_bar,
                }[connectionQuality],
                color: {
                  ConnectionQuality.excellent: Colors.green,
                  ConnectionQuality.good: Colors.orange,
                  ConnectionQuality.poor: Colors.red,
                }[connectionQuality],
                size: 16,
              )
            else
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ).paddingAll(3),
          ],
        ),
      );
}
