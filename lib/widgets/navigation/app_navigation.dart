import 'package:flutter/material.dart';
import 'package:get/utils.dart';

abstract class AppNavigation {
  static List<AppNavigationDestination> destinations = [
    AppNavigationDestination(
      icon: const Icon(Icons.feed),
      label: 'feed'.tr,
      page: 'feed',
    ),
    AppNavigationDestination(
      icon: const Icon(Icons.forum),
      label: 'chat'.tr,
      page: 'chat',
    ),
    AppNavigationDestination(
      icon: const Icon(Icons.workspaces),
      label: 'realms'.tr,
      page: 'realms',
    ),
    AppNavigationDestination(
      icon: const Icon(Icons.account_circle),
      label: 'account'.tr,
      page: 'account',
    ),
  ];

  static List<String> get destinationPages =>
      AppNavigation.destinations.map((x) => x.page).toList();
}

class AppNavigationDestination {
  final Widget icon;
  final String label;
  final String page;

  AppNavigationDestination({
    required this.icon,
    required this.label,
    required this.page,
  });
}
