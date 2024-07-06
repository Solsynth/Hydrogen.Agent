import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/prev_page.dart';

class CenteredShell extends StatelessWidget {
  final bool showAppBar;
  final GoRouterState state;
  final Widget child;

  const CenteredShell({
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
              title: AppBarTitle(state.topRoute?.name?.tr ?? 'page'.tr),
              centerTitle: false,
              toolbarHeight: SolianTheme.toolbarHeight(context),
              leading: canPop ? const PrevPageButton() : null,
              automaticallyImplyLeading: false,
            )
          : null,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      ),
    );
  }
}