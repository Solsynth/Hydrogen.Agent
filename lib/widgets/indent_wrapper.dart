import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/common_wrapper.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class IndentWrapper extends LayoutWrapper {
  final bool hideDrawer;

  const IndentWrapper({
    super.key,
    super.child,
    required super.title,
    super.floatingActionButton,
    super.appBarActions,
    this.hideDrawer = false,
    super.noSafeArea = false,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final content = child ?? Container();

    return Scaffold(
      appBar: AppBar(
        leading: hideDrawer ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => router.pop(),
        ) : null,
        title: Text(title),
        actions: appBarActions,
      ),
      floatingActionButton: floatingActionButton,
      drawer: const SolianNavigationDrawer(),
      body: noSafeArea ? content : SafeArea(child: content),
    );
  }
}
