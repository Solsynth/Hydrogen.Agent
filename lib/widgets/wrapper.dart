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
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(cfg.title),
              elevation: 10.0,
              expandedHeight: 50,
              floating: true,
              snap: true,
            ),
          ];
        },
        body: child ?? Container(),
      ),
    );
  }
}
