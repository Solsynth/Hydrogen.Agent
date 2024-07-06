import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/platform.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';
import 'package:solian/widgets/navigation/app_navigation_bottom_bar.dart';
import 'package:solian/widgets/navigation/app_navigation_rail.dart';

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

  @override
  Widget build(BuildContext context) {
    final routeName = AppRouter
        .instance.routerDelegate.currentConfiguration.lastOrNull?.route.name;
    final showBottom = showBottomNavigation ??
        AppNavigation.destinationPages.contains(routeName);

    return Scaffold(
      body: Column(
        children: [
          if (PlatformInfo.isMacOS)
            Container(
              height: 28,
              color: Theme.of(context).colorScheme.surface,
            ),
          if (PlatformInfo.isMacOS)
            const Divider(
              thickness: 0.3,
              height: 0.3,
            ),
          Expanded(
            child: SolianTheme.isLargeScreen(context)
                ? Row(
                    children: [
                      if (showNavigation) const AppNavigationRail(),
                      if (showNavigation)
                        const VerticalDivider(thickness: 0.3, width: 1),
                      Expanded(child: child),
                    ],
                  )
                : Stack(
                    children: [
                      child,
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: const AppNavigationBottomBar()
                            .animate(target: showBottom ? 0 : 1)
                            .slideY(
                              duration: 250.ms,
                              begin: 0,
                              end: 1,
                              curve: Curves.easeInToLinear,
                            ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
