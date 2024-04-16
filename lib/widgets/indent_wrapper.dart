import 'package:flutter/material.dart';
import 'package:solian/widgets/common_wrapper.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class IndentWrapper extends LayoutWrapper {
  final bool? hideDrawer;

  const IndentWrapper({
    super.key,
    super.child,
    required super.title,
    super.floatingActionButton,
    super.appBarActions,
    this.hideDrawer,
    super.noSafeArea,
  }) : super();

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
