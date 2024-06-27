import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SidebarPlaceholder extends StatelessWidget {
  const SidebarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.menu_open, size: 50),
    );
  }
}
