import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyPagePlaceholder extends StatelessWidget {
  const EmptyPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/logo.png', width: 80, height: 80),
    );
  }
}
