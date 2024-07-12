import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/navigation/app_navigation_drawer.dart';
import 'package:solian/widgets/navigation/app_navigation_rail.dart';

final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

class RootShell extends StatelessWidget {
  final bool showSidebar;
  final bool showNavigation;
  final bool? showBottomNavigation;
  final GoRouterState state;
  final Widget child;

  const RootShell({
    super.key,
    required this.state,
    required this.child,
    this.showSidebar = true,
    this.showNavigation = true,
    this.showBottomNavigation,
  });

  void closeDrawer() {
    rootScaffoldKey.currentState!.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final routeName = state.topRoute?.name;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: AppNavigationDrawer(
        key: const ValueKey('navigation-drawer'),
        routeName: routeName,
      ),
      body: SolianTheme.isLargeScreen(context)
          ? Row(
              children: [
                if (showNavigation) const AppNavigationRail(),
                if (showNavigation)
                  const VerticalDivider(thickness: 0.3, width: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
