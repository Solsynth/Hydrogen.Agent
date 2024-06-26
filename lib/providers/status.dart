import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class StatusController extends GetConnect {
  static Map<String, (Widget, String, String?)> presetStatuses = {
    'online': (
      const Icon(Icons.circle, color: Colors.green),
      'accountStatusOnline'.tr,
      null,
    ),
    'silent': (
      const Icon(Icons.do_not_disturb_on, color: Colors.red),
      'accountStatusSilent'.tr,
      'accountStatusSilentDesc'.tr,
    ),
    'invisible': (
      const Icon(Icons.circle, color: Colors.grey),
      'accountStatusInvisible'.tr,
      'accountStatusInvisibleDesc'.tr,
    ),
  };

  @override
  void onInit() {
    final AuthProvider auth = Get.find();

    httpClient.baseUrl = ServiceFinder.services['passport'];
    httpClient.addAuthenticator(auth.requestAuthenticator);
  }

  Future<Response> getCurrentStatus() => get('/api/users/me/status');

  Future<Response> getSomeoneStatus(String name) =>
      get('/api/users/$name/status');

  static (Widget, String) determineStatus(AccountStatus status,
      {double size = 14}) {
    Widget icon;
    String? text = status.status?.label;

    if (status.isDisturbable && status.isOnline) {
      icon = Icon(Icons.circle, color: Colors.green, size: size);
      text ??= 'accountStatusOnline'.tr;
    } else if (!status.isDisturbable && status.isOnline) {
      icon = Icon(Icons.do_not_disturb_on, color: Colors.red, size: size);
      text ??= 'accountStatusSilent'.tr;
    } else {
      icon = Icon(Icons.circle, color: Colors.grey, size: size);
      text ??= 'accountStatusOffline'.tr;
    }
    return (icon, text);
  }
}
