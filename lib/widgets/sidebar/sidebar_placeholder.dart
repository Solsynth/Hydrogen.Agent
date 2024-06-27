import 'package:flutter/material.dart';

class SidebarPlaceholder extends StatelessWidget {
  const SidebarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Icon(Icons.menu_open, size: 50),
      ),
    );
  }
}
