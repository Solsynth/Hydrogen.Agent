import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/root_container.dart';

class TitleShell extends StatelessWidget {
  final bool showAppBar;
  final bool isCenteredTitle;
  final bool isResponsive;
  final String? title;
  final GoRouterState? state;
  final Widget child;

  const TitleShell({
    super.key,
    required this.child,
    this.title,
    this.state,
    this.showAppBar = true,
    this.isCenteredTitle = false,
    this.isResponsive = false,
  });

  @override
  Widget build(BuildContext context) {
    assert(state != null || title != null);

    final widget = Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: AppBarLeadingButton.adaptive(context),
              title: AppBarTitle(
                title ?? (state!.topRoute?.name?.tr ?? 'page'.tr),
              ),
              centerTitle: isCenteredTitle,
              toolbarHeight: AppTheme.toolbarHeight(context),
              actions: [
                const BackgroundStateWidget(),
                SizedBox(
                  width: AppTheme.isLargeScreen(context) ? 8 : 16,
                ),
              ],
            )
          : null,
      body: child,
    );

    if (isResponsive) {
      return ResponsiveRootContainer(child: widget);
    } else {
      return RootContainer(child: widget);
    }
  }
}
