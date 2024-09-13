import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/sidebar/sidebar_placeholder.dart';

class SidebarShell extends StatelessWidget {
  final bool showAppBar;
  final GoRouterState state;
  final Widget child;

  final bool sidebarFirst;
  final Widget? sidebar;

  const SidebarShell({
    super.key,
    required this.child,
    required this.state,
    this.showAppBar = true,
    this.sidebarFirst = false,
    this.sidebar,
  });

  List<Widget> buildContent(BuildContext context) {
    return [
      Flexible(
        flex: 2,
        child: child,
      ),
      if (AppTheme.isExtraLargeScreen(context))
        const VerticalDivider(thickness: 0.3, width: 1),
      if (AppTheme.isExtraLargeScreen(context))
        Flexible(
          flex: 1,
          child: sidebar ?? const SidebarPlaceholder(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: AppBarLeadingButton.adaptive(context),
              title: AppBarTitle(state.topRoute?.name?.tr ?? 'page'.tr),
              centerTitle: false,
              toolbarHeight: AppTheme.toolbarHeight(context),
            )
          : null,
      body: AppTheme.isLargeScreen(context)
          ? Row(
              children: sidebarFirst
                  ? buildContent(context).reversed.toList()
                  : buildContent(context),
            )
          : child,
    );
  }
}
