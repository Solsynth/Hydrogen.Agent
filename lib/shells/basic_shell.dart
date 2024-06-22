import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/prev_page.dart';

class BasicShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const BasicShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final canPop = AppRouter.instance.canPop();

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(state.topRoute?.name?.tr ?? 'page'.tr),
        centerTitle: false,
        toolbarHeight: SolianTheme.toolbarHeight(context),
        leading: canPop ? const PrevPageButton() : null,
        automaticallyImplyLeading: false,
      ),
      body: child,
    );
  }
}
