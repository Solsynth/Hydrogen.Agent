import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:solian/widgets/navigation/app_navigation_bottom_bar.dart';
import 'package:solian/widgets/navigation/app_navigation_rail.dart';

class NavShell extends StatelessWidget {
  final bool showAppBar;
  final GoRouterState state;
  final Widget child;

  const NavShell({
    super.key,
    required this.child,
    required this.state,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = AppRouter.instance.canPop();

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
      bottomNavigationBar: SolianTheme.isLargeScreen(context)
          ? null
          : const AppNavigationBottomBar(),
      body: SolianTheme.isLargeScreen(context)
          ? Row(
              children: [
                const AppNavigationRail(),
                const VerticalDivider(thickness: 0.3, width: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
