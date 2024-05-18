import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';

class AppNavigationBottomBar extends StatefulWidget {
  const AppNavigationBottomBar({super.key});

  @override
  State<AppNavigationBottomBar> createState() => _AppNavigationBottomBarState();
}

class _AppNavigationBottomBarState extends State<AppNavigationBottomBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: AppNavigation.destinations.map(
        (e) => BottomNavigationBarItem(
          icon: e.icon,
          label: e.label,
        ),
      ).toList(),
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      currentIndex: _selectedIndex,
      showUnselectedLabels: false,
      onTap: (idx) {
        setState(() => _selectedIndex = idx);
        AppRouter.instance.goNamed(AppNavigation.destinations[idx].page);
      },
    );
  }
}
