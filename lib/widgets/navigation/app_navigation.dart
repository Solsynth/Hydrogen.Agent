import 'package:flutter/material.dart';
import 'package:get/utils.dart';

abstract class AppNavigation {
  static List<AppNavigationDestination> destinations = [
    AppNavigationDestination(
      icon: const Icon(Icons.public),
      label: 'social'.tr,
      page: 'social',
    ),
    AppNavigationDestination(
      icon: const Icon(Icons.contacts),
      label: 'contact'.tr,
      page: 'contact',
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
