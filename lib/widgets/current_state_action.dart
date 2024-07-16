import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/providers/auth.dart';

class BackgroundStateWidget extends StatelessWidget {
  const BackgroundStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();
    final WebSocketProvider ws = Get.find();

    return Obx(() {
      final disconnected = ws.isConnected.isFalse;
      final connecting = ws.isConnecting.isTrue;

      return Row(children: [
        if (disconnected && !connecting)
          FutureBuilder(
            future: auth.isAuthorized,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == false) {
                return const SizedBox();
              }
              return IconButton(
                tooltip: [
                  if (ws.isConnected.isFalse)
                    'Lost Connection with Solar Network...',
                ].join('\n'),
                icon: const Icon(Icons.wifi_off)
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
                onPressed: () {
                  if (ws.isConnected.isFalse) ws.connect();
                },
              );
            },
          ),
        if (connecting)
          FutureBuilder(
            future: auth.isAuthorized,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == false) {
                return const SizedBox();
              }
              return IconButton(
                tooltip: [
                  if (ws.isConnecting.isTrue)
                    'Waiting Solar Network Connection...',
                ].join('\n'),
                icon: const Icon(Icons.sync)
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 1850.ms, begin: 1, end: 0),
                onPressed: () {},
              );
            },
          ),
      ]);
    });
  }
}
