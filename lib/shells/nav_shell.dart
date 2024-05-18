import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/navigation/app_navigation_bottom_bar.dart';
import 'package:solian/widgets/navigation/app_navigation_rail.dart';

class NavShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const NavShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.topRoute?.name?.tr ?? 'page'.tr),
        centerTitle: false,
        elevation: SolianTheme.isLargeScreen(context) ? 1 : 0,
        titleSpacing: 24,
      ),
      bottomNavigationBar: SolianTheme.isLargeScreen(context) ? null : const AppNavigationBottomBar(),
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
