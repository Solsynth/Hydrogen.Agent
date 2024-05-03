import 'package:flutter/material.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class IndentScaffold extends StatelessWidget {
  final Widget? child;
  final Widget? floatingActionButton;
  final Widget? appBarLeading;
  final List<Widget>? appBarActions;
  final bool noSafeArea;
  final bool hideDrawer;
  final bool fixedAppBarColor;
  final String title;

  const IndentScaffold({
    super.key,
    this.child,
    required this.title,
    this.floatingActionButton,
    this.appBarLeading,
    this.appBarActions,
    this.hideDrawer = false,
    this.fixedAppBarColor = false,
    this.noSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = child ?? Container();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: appBarLeading,
        actions: appBarActions,
        centerTitle: false,
        elevation: fixedAppBarColor ? 4 : null,
      ),
      floatingActionButton: floatingActionButton,
      drawer: !hideDrawer ? const SolianNavigationDrawer() : null,
      drawerScrimColor: SolianTheme.isLargeScreen(context) ? Colors.transparent : null,
      body: noSafeArea ? content : SafeArea(child: content),
    );
  }
}
