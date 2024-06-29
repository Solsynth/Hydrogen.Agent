import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension SolianExtenions on BuildContext {
  void showSnackbar(String content) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }

  void clearSnackbar() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }

  Future<void> showErrorDialog(dynamic exception) {
    return showDialog<void>(
      useRootNavigator: true,
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text('errorHappened'.tr),
        content: Text(exception.toString().capitalize!),
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
