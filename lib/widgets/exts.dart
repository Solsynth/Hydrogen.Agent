import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension SolianCommonExtensions on BuildContext {
  Future<void> showErrorDialog(dynamic exception) => showDialog<void>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(this)!.errorHappened),
          content: Text(exception.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(this)!.confirmOkay),
            )
          ],
        ),
      );
}
