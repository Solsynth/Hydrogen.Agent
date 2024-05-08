import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class IndentScaffold extends StatelessWidget {
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? appBarLeading;
  final List<Widget>? appBarActions;
  final bool hideDrawer;
  final bool showSafeArea;
  final bool fixedAppBarColor;
  final String title;

  const IndentScaffold({
    super.key,
    this.body,
    required this.title,
    this.floatingActionButton,
    this.appBarLeading,
    this.appBarActions,
    this.hideDrawer = false,
    this.showSafeArea = false,
    this.fixedAppBarColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (SolianRouter.router.canPop()) {
          SolianRouter.router.pop();
        }
      },
    );

    final drawerButton = Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu),
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: appBarLeading ?? (hideDrawer ? backButton : drawerButton),
        actions: appBarActions,
        centerTitle: false,
        elevation: fixedAppBarColor ? 4 : null,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: floatingActionButton,
      drawer: !hideDrawer ? const SolianNavigationDrawer() : null,
      drawerScrimColor: SolianTheme.isLargeScreen(context) ? Colors.transparent : null,
      body: showSafeArea ? SafeArea(child: body ?? Container()) : body,
    );
  }
}
