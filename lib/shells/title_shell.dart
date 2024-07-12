import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';

class TitleShell extends StatelessWidget {
  final bool showAppBar;
  final GoRouterState state;
  final Widget child;

  const TitleShell({
    super.key,
    required this.child,
    required this.state,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: AppBarTitle(state.topRoute?.name?.tr ?? 'page'.tr),
              centerTitle: false,
              toolbarHeight: SolianTheme.toolbarHeight(context),
            )
          : null,
      body: child,
    );
  }
}
