import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';

class AppNavigationRail extends StatefulWidget {
  const AppNavigationRail({super.key});

  @override
  State<AppNavigationRail> createState() => _AppNavigationRailState();
}

class _AppNavigationRailState extends State<AppNavigationRail> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      destinations: AppNavigation.destinations.map(
        (e) => NavigationRailDestination(
          icon: e.icon,
          label: Text(e.label),
        ),
      ).toList(),
      labelType: NavigationRailLabelType.selected,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) {
        setState(() => _selectedIndex = idx);
        AppRouter.instance.pushNamed(AppNavigation.destinations[idx].page);
      },
    );
  }
}
