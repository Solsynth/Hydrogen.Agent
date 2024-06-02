import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SidebarPlaceholder extends StatelessWidget {
  const SidebarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_open, size: 48),
            const SizedBox(height: 8),
            Text('sidebarPlaceholder'.tr, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
