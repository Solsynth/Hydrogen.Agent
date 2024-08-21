import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/unauthorized.dart';

extension SolianExtenions on BuildContext {
  void showSnackbar(String content, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(content),
      action: action,
    ));
  }

  void clearSnackbar() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }

  Future<void> showModalDialog(String title, desc) {
    return showDialog<void>(
      useRootNavigator: true,
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('okay'.tr),
          )
        ],
      ),
    );
  }

  Future<void> showInfoDialog(String title, body) {
    return showDialog<void>(
      useRootNavigator: true,
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('okay'.tr),
          )
        ],
      ),
    );
  }

  Future<void> showErrorDialog(dynamic exception) {
    Widget content = Text(exception.toString().capitalize!);
    if (exception is UnauthorizedException) {
      content = Text('errorHappenedUnauthorized'.tr);
    }

    return showDialog<void>(
      useRootNavigator: true,
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text('errorHappened'.tr),
        content: content,
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
