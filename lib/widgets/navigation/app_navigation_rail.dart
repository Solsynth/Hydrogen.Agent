import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';

class AppNavigationRail extends StatefulWidget {
  final int initialIndex;

  const AppNavigationRail({super.key, this.initialIndex = 0});

  @override
  State<AppNavigationRail> createState() => _AppNavigationRailState();
}

class _AppNavigationRailState extends State<AppNavigationRail> {
  int? _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex >= 0) {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: NavigationRail(
        selectedIndex: _currentIndex,
        labelType: NavigationRailLabelType.selected,
        groupAlignment: -1,
        destinations: AppNavigation.destinations
            .sublist(0, AppNavigation.destinations.length - 1)
            .map(
              (x) => NavigationRailDestination(
                icon: x.icon,
                label: Text(x.label),
              ),
            )
            .toList(),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: IconButton(
              icon: AppNavigation.destinations.last.icon,
              tooltip: AppNavigation.destinations.last.label,
              onPressed: () {
                setState(() => _currentIndex = null);
                AppRouter.instance
                    .goNamed(AppNavigation.destinations.last.page);
              },
            ),
          ),
        ),
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          AppRouter.instance.goNamed(AppNavigation.destinations[idx].page);
        },
      ).paddingOnly(
        top: max(16, MediaQuery.of(context).padding.top),
        bottom: max(16, MediaQuery.of(context).padding.bottom),
      ),
    );
  }
}
