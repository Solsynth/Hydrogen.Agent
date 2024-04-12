import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LayoutConfig {
  String title = "Solian";

  LayoutConfig(BuildContext context) {
    title = AppLocalizations.of(context)!.solian;
  }
}