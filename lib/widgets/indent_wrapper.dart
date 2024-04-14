import 'package:flutter/material.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class IndentWrapper extends StatelessWidget {
  final Widget? child;
  final Widget? floatingActionButton;
  final List<Widget>? appBarActions;
  final bool? hideDrawer;
  final bool? noSafeArea;
  final String title;

  const IndentWrapper({super.key, this.child, required this.title, this.floatingActionButton, this.appBarActions, this.hideDrawer, this.noSafeArea});

  @override
  Widget build(BuildContext context) {
    final content = child ?? Container();

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: appBarActions),
      floatingActionButton: floatingActionButton,
      drawer: (hideDrawer ?? false) ? null : const SolianNavigationDrawer(),
      body: (noSafeArea ?? false) ? content : SafeArea(child: content),
    );
  }
}
