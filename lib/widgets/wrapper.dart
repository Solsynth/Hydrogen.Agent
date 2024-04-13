import 'package:flutter/material.dart';
import 'package:solian/widgets/navigation_drawer.dart';

class LayoutWrapper extends StatelessWidget {
  final Widget? child;
  final String title;

  const LayoutWrapper({super.key, this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SolianNavigationDrawer(),
      appBar: AppBar(title: Text(title)),
      body: child ?? Container(),
    );
  }
}
