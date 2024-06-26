import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class StatusProvider extends GetConnect {
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

  Future<Response> getCurrentStatus() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient('passport');

    return await client.get('/api/users/me/status');
  }

  Future<Response> getSomeoneStatus(String name) =>
      get('/api/users/$name/status');

  Future<Response> setStatus(
    String type,
    String? label,
    int attitude, {
    bool isUpdate = false,
    bool isSilent = false,
    bool isInvisible = false,
    DateTime? clearAt,
  }) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient('passport');

    final payload = {
      'type': type,
      'label': label,
      'is_no_disturb': isSilent,
      'is_invisible': isInvisible,
      'clear_at': clearAt?.toUtc().toIso8601String()
    };

    Response resp;
    if (!isUpdate) {
      resp = await client.post('/api/users/me/status', payload);
    } else {
      resp = await client.put('/api/users/me/status', payload);
    }

    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> clearStatus() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient('passport');

    final resp = await client.delete('/api/users/me/status');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  static (Widget, String) determineStatus(AccountStatus status,
      {double size = 14}) {
    Widget icon;
    String? text;

    if (!presetStatuses.keys.contains(status.status?.type)) {
      text = status.status?.label;
    }

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
