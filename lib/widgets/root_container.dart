import 'package:flutter/material.dart';

class RootContainer extends StatelessWidget {
  final Widget? child;

  const RootContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
