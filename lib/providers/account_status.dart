import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/unauthorized.dart';
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

    httpClient.baseUrl = ServiceFinder.buildUrl('auth', null);
    httpClient.addAuthenticator(auth.requestAuthenticator);
  }

  Future<Response> getCurrentStatus() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = auth.configureClient('auth');

    return await client.get('/users/me/status');
  }

  Future<Response> getSomeoneStatus(String name) => get('/users/$name/status');

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
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = auth.configureClient('auth');

    final payload = {
      'type': type,
      'label': label,
      'attitude': attitude,
      'is_no_disturb': isSilent,
      'is_invisible': isInvisible,
      'clear_at': clearAt?.toUtc().toIso8601String()
    };

    Response resp;
    if (!isUpdate) {
      resp = await client.post('/users/me/status', payload);
    } else {
      resp = await client.put('/users/me/status', payload);
    }

    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> clearStatus() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = auth.configureClient('auth');

    final resp = await client.delete('/users/me/status');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  static (Widget, Color, String) determineStatus(AccountStatus status,
      {double size = 14}) {
    Widget icon;
    Color color;
    String? text;

    if (!presetStatuses.keys.contains(status.status?.type)) {
      text = status.status?.label;
    }

    if (status.isDisturbable && status.isOnline) {
      color = Colors.green;
      icon = Icon(Icons.circle, color: color, size: size);
      text ??= 'accountStatusOnline'.tr;
    } else if (!status.isDisturbable && status.isOnline) {
      color = Colors.red;
      icon = Icon(Icons.do_not_disturb_on, color: color, size: size);
      text ??= 'accountStatusSilent'.tr;
    } else {
      color = Colors.grey;
      icon = Icon(Icons.circle, color: color, size: size);
      text ??= 'accountStatusOffline'.tr;
    }
    return (icon, color, text);
  }
}
