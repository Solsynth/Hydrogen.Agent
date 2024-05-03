import 'package:flutter/material.dart';
import 'package:solian/widgets/empty.dart';

class TwoColumnLayout extends StatelessWidget {
  final Widget sideChild;
  final Widget? mainChild;

  const TwoColumnLayout({
    super.key,
    required this.sideChild,
    required this.mainChild,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: sideChild,
        ),
        const VerticalDivider(width: 0.3, thickness: 0.3),
        Expanded(child: mainChild ?? const PageEmptyWidget()),
      ],
    );
  }
}
