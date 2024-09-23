import 'package:flutter/material.dart';
import 'package:get/utils.dart';

abstract class AppNavigation {
  static List<AppNavigationDestination> destinations = [
    AppNavigationDestination(
      icon: Icons.dashboard,
      label: 'dashboard'.tr,
      page: 'dashboard',
    ),
    AppNavigationDestination(
      icon: Icons.explore,
      label: 'explore'.tr,
      page: 'explore',
    ),
    AppNavigationDestination(
      icon: Icons.workspaces,
      label: 'realms'.tr,
      page: 'realms',
    ),
    AppNavigationDestination(
      icon: Icons.forum,
      label: 'chat'.tr,
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
