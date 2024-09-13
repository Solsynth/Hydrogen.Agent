import 'package:flutter/material.dart';
import 'package:solian/theme.dart';

class AppBarTitle extends StatelessWidget {
  final String title;

  const AppBarTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    if (AppTheme.isSpecializedMacOS(context)) {
      return Text(title);
    } else {
      return Text(title);
    }
  }
}
