import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/call.dart';

class ChatCallCurrentIndicator extends StatelessWidget {
  const ChatCallCurrentIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider provider = Get.find();

    if (provider.current.value == null || provider.channel.value == null) {
      return const SizedBox();
    }

    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      leading: const Icon(Icons.call),
      title: Text(provider.channel.value!.name),
      subtitle: Text('callAlreadyOngoing'.tr),
      onTap: () {
        provider.gotoScreen(context);
      },
    );
  }
}
