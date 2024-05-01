import 'package:flutter/material.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class LayoutWrapper extends StatelessWidget {
  final Widget? child;
  final Widget? floatingActionButton;
  final List<Widget>? appBarActions;
  final bool noSafeArea;
  final String title;

  const LayoutWrapper({
    super.key,
    this.child,
    required this.title,
    this.floatingActionButton,
    this.appBarActions,
    this.noSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = child ?? Container();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
        centerTitle: false,
      ),
      floatingActionButton: floatingActionButton,
      drawer: const SolianNavigationDrawer(),
      body: noSafeArea ? content : SafeArea(child: content),
    );
  }
}
