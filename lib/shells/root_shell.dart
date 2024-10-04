import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/navigation/app_navigation_bottom.dart';

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

    if (routeName != null) {
      FirebaseAnalytics.instance.logEvent(
        name: 'screen_view',
        parameters: {
          'firebase_screen': routeName,
        },
      );
    }

    return Scaffold(
      key: rootScaffoldKey,
      bottomNavigationBar: const AppNavigationBottom(),
      body: AppTheme.isLargeScreen(context)
          ? Row(
              children: [
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
