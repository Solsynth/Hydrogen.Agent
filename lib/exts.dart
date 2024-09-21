import 'dart:math' as math;

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';

extension AppExtensions on BuildContext {
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

  Future<bool> showConfirmDialog(String title, body) async {
    return await showDialog<bool>(
          useRootNavigator: true,
          context: this,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('okay'.tr),
              )
            ],
          ),
        ) ??
        false;
  }

  Future<bool> showSlideToConfirmDialog(String title, body) async {
    return await showDialog<bool>(
          useRootNavigator: true,
          context: this,
          builder: (ctx) => AlertDialog(
            title: Text(title, textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(body, textAlign: TextAlign.center),
                  const Gap(28),
                  ActionSlider.standard(
                    icon: const Icon(Icons.send),
                    iconAlignment: Alignment.center,
                    sliderBehavior: SliderBehavior.move,
                    actionThresholdType: ThresholdType.release,
                    toggleColor: Colors.red,
                    action: (controller) async {
                      controller.success();
                      await Future.delayed(const Duration(milliseconds: 500));
                      Navigator.pop(ctx, true);
                    },
                    child: Text('slideToConfirm'.tr),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr),
              )
            ],
          ),
        ) ??
        false;
  }

  Future<void> showErrorDialog(dynamic exception) {
    Widget content = Text(exception.toString().capitalize!);
    if (exception is UnauthorizedException) {
      content = Text('errorHappenedUnauthorized'.tr);
    }
    if (exception is RequestException) {
      String overall;
      switch (exception.data.statusCode) {
        case 400:
          overall = 'errorHappenedRequestBad'.tr;
          break;
        case 401:
          overall = 'errorHappenedUnauthorized'.tr;
          break;
        case 403:
          overall = 'errorHappenedRequestForbidden'.tr;
          break;
        case 404:
          overall = 'errorHappenedRequestNotFound'.tr;
          break;
        case null:
          overall = 'errorHappenedRequestConnection'.tr;
          break;
        default:
          overall = 'errorHappenedRequestUnknown'.tr;
          break;
      }

      if (exception.data.statusCode != null) {
        content = Text(
          '$overall\n\n(${exception.data.statusCode}) ${exception.data.bodyString}',
        );
      } else {
        content = Text(overall);
      }
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

extension ByteFormatter on int {
  String formatBytes({int decimals = 2}) {
    if (this == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = [
      'Bytes',
      'KiB',
      'MiB',
      'GiB',
      'TiB',
      'PiB',
      'EiB',
      'ZiB',
      'YiB'
    ];
    final i = (math.log(this) / math.log(k)).floor().toInt();
    return '${(this / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
  }
}
