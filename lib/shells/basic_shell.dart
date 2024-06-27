import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:solian/widgets/sidebar/sidebar_placeholder.dart';

class BasicShell extends StatelessWidget {
  final bool showAppBar;
  final GoRouterState state;
  final Widget child;

  final bool sidebarFirst;
  final Widget? sidebar;

  const BasicShell({
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

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: AppBarTitle(state.topRoute?.name?.tr ?? 'page'.tr),
              centerTitle: false,
              toolbarHeight: SolianTheme.toolbarHeight(context),
              leading: canPop ? const PrevPageButton() : null,
              automaticallyImplyLeading: false,
            )
          : null,
      body: SolianTheme.isLargeScreen(context)
          ? Row(
              children: sidebarFirst
                  ? buildContent(context).reversed.toList()
                  : buildContent(context),
            )
          : child,
    );
  }
}
