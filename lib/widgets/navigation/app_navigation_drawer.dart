import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/shells/root_shell.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) {
        setState(() => _selectedIndex = idx);
        AppRouter.instance.goNamed(AppNavigation.destinations[idx].page);
        rootScaffoldKey.currentState!.closeDrawer();
      },
      children: [
        ...AppNavigation.destinations.map(
          (e) => NavigationDrawerDestination(
            icon: e.icon,
            label: Text(e.label),
          ),
        )
      ],
    );
  }
}
