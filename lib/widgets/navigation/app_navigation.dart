import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:solian/widgets/navigation/app_account_widget.dart';

abstract class AppNavigation {
  static List<AppNavigationDestination> destinations = [
    AppNavigationDestination(
      icon: const Icon(Icons.dashboard),
      label: 'dashboard'.tr,
      page: 'dashboard',
    ),
    AppNavigationDestination(
      icon: const Icon(Icons.explore),
      label: 'explore'.tr,
      page: 'explore',
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
      icon: const AppAccountWidget(),
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
