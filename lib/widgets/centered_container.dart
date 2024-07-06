import 'package:flutter/material.dart';

class CenteredContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
