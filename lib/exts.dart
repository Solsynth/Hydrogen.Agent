import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension SolianExtenions on BuildContext {
  void showSnackbar(String content) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }

  Future<void> showErrorDialog(dynamic exception) {
    String formatMessage(dynamic exception) {
      final message = exception.toString();
      if (message.trim().isEmpty) return '';
      return message
          .split(' ')
          .map((element) =>
              '${element[0].toUpperCase()}${element.substring(1).toLowerCase()}')
          .join(' ');
    }

    return showDialog<void>(
      useRootNavigator: true,
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text('errorHappened'.tr),
        content: Text(formatMessage(exception)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('okay'.tr),
          )
        ],
      ),
    );
  }
}
