import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/layout_provider.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class LayoutWrapper extends StatelessWidget {
  final Widget? child;

  const LayoutWrapper({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    var cfg = context.watch<LayoutConfig>();

    return Scaffold(
      drawer: const SolianNavigationDrawer(),
      appBar: AppBar(title: Text(cfg.title)),
      body: child ?? Container(),
    );
  }
}
