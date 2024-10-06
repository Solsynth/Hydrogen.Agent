import 'package:flutter/material.dart';
import 'package:solian/widgets/root_container.dart';

class EmptyPagePlaceholder extends StatelessWidget {
  const EmptyPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveRootContainer(
      child: Center(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Image.asset('assets/logo.png', width: 80, height: 80),
        ),
      ),
    );
  }
}
