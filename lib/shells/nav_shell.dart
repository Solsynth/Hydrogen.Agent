import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:solian/widgets/navigation/app_navigation_bottom_bar.dart';
import 'package:solian/widgets/navigation/app_navigation_rail.dart';
import 'package:solian/widgets/sidebar/sidebar_placeholder.dart';

class NavShell extends StatelessWidget {
  final bool showAppBar;
  final bool showSidebar;
  final bool showNavigation;
  final bool? showBottomNavigation;
  final GoRouterState state;
  final Widget child;

  final bool sidebarFirst;
  final Widget? sidebar;

  const NavShell({
    super.key,
    required this.child,
    required this.state,
    this.showAppBar = true,
    this.showSidebar = true,
    this.showNavigation = true,
    this.showBottomNavigation,
    this.sidebarFirst = false,
    this.sidebar,
  });

  List<Widget> buildContent(BuildContext context) {
    return [
      Flexible(
        flex: 2,
        child: child,
      ),
      if (SolianTheme.isExtraLargeScreen(context))
        const VerticalDivider(thickness: 0.3, width: 1),
      if (SolianTheme.isExtraLargeScreen(context))
        Flexible(
          flex: 1,
          child: sidebar ?? const SidebarPlaceholder(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canPop = AppRouter.instance.canPop();

    final routeName =
        AppRouter.instance.routerDelegate.currentConfiguration.last.route.name;
    final showBottom = showBottomNavigation ??
        AppNavigation.destinationPages.contains(routeName);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(state.topRoute?.name?.tr ?? 'page'.tr),
              centerTitle: false,
              titleSpacing: canPop ? null : 24,
              elevation: SolianTheme.isLargeScreen(context) ? 1 : 0,
              leading: canPop ? const PrevPageButton() : null,
              automaticallyImplyLeading: false,
            )
          : null,
      bottomNavigationBar: (SolianTheme.isLargeScreen(context) ||
              !(showNavigation && showBottom))
          ? null
          : const AppNavigationBottomBar(),
      body: SolianTheme.isLargeScreen(context)
          ? Row(
              children: [
                if (showNavigation) const AppNavigationRail(),
                if (showNavigation)
                  const VerticalDivider(thickness: 0.3, width: 1),
                if (showSidebar && sidebarFirst)
                  ...buildContent(context).reversed
                else if (showSidebar)
                  ...buildContent(context)
                else
                  Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
