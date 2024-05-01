import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension SolianCommonExtensions on BuildContext {
  Future<void> showErrorDialog(dynamic exception) {
    String formatMessage(dynamic exception) {
      final message = exception.toString();
      if (message.trim().isEmpty) return '';
      return message
          .split(' ')
          .map((element) => "${element[0].toUpperCase()}${element.substring(1).toLowerCase()}")
          .join(" ");
    }

    return showDialog<void>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(this)!.errorHappened),
        content: Text(formatMessage(exception)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(this)!.confirmOkay),
          )
        ],
      ),
    );
  }
}
