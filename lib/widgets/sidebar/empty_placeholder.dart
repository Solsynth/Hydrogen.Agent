import 'package:flutter/material.dart';

class EmptyPagePlaceholder extends StatelessWidget {
  const EmptyPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Image.asset('assets/logo.png', width: 80, height: 80),
        ),
      ),
    );
  }
}
