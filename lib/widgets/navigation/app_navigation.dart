import 'package:flutter/material.dart';
import 'package:get/utils.dart';

abstract class AppNavigation {
  static List<AppNavigationDestination> destinations = [
    AppNavigationDestination(
      icon: Icons.home,
      label: 'home'.tr,
      page: 'home',
    ),
    AppNavigationDestination(
      icon: Icons.workspaces,
      label: 'realms'.tr,
      page: 'realms',
    ),
    AppNavigationDestination(
      icon: Icons.forum,
      label: 'channelTypeDirect'.tr,
      page: 'chat',
    ),
  ];

  static List<String> get destinationPages =>
      AppNavigation.destinations.map((x) => x.page).toList();
}

class AppNavigationDestination {
  final IconData icon;
  final String label;
  final String page;

  AppNavigationDestination({
    required this.icon,
    required this.label,
    required this.page,
  });
}
