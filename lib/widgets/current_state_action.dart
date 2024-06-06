import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/chat.dart';

class BackgroundStateWidget extends StatelessWidget {
  const BackgroundStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountProvider account = Get.find();
    final ChatProvider chat = Get.find();

    return Obx(() {
      final disconnected =
          chat.isConnected.isFalse || account.isConnected.isFalse;
      final connecting =
          chat.isConnecting.isTrue || account.isConnecting.isTrue;

      return Row(children: [
        if (disconnected && !connecting)
          IconButton(
            tooltip: [
              if (account.isConnected.isFalse)
                'Lost Connection with Passport Server...',
              if (chat.isConnected.isFalse)
                'Lost Connection with Messaging Server...',
            ].join('\n'),
            icon: const Icon(Icons.wifi_off)
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 800.ms)
                .then()
                .fadeOut(duration: 800.ms),
            onPressed: () {
              if (account.isConnected.isFalse) account.connect();
              if (chat.isConnected.isFalse) chat.connect();
            },
          ),
        if (connecting)
          IconButton(
            tooltip: [
              if (account.isConnecting.isTrue)
                'Waiting Passport Server Response...',
              if (chat.isConnecting.isTrue)
                'Waiting Messaging Server Response...',
            ].join('\n'),
            icon: const Icon(Icons.sync)
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1850.ms, begin: 1, end: 0),
            onPressed: () {},
          ),
      ]);
    });
  }
}
