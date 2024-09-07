import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/call.dart';

class ChatCallCurrentIndicator extends StatelessWidget {
  const ChatCallCurrentIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider call = Get.find();

    return Obx(() {
      if (call.current.value == null || call.channel.value == null) {
        return const SizedBox.shrink();
      }

      return ListTile(
        tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 32),
        leading: const Icon(Icons.call),
        title: Text(call.channel.value!.name),
        subtitle: Text('callAlreadyOngoing'.tr),
      );
    });
  }
}
