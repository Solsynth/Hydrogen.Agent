import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/services.dart';

class TokenSet {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiredAt;

  TokenSet({
    required this.accessToken,
    required this.refreshToken,
    this.expiredAt,
  });

  factory TokenSet.fromJson(Map<String, dynamic> json) => TokenSet(
        accessToken: json['access_token'],
        refreshToken: json['refresh_token'],
        expiredAt: json['expired_at'] != null
            ? DateTime.parse(json['expired_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expired_at': expiredAt?.toIso8601String(),
      };

  bool get isExpired => expiredAt?.isBefore(DateTime.now()) ?? true;
}

TokenSet? globalCredentials;

class RiskyAuthenticateException implements Exception {
  final int ticketId;

  RiskyAuthenticateException(this.ticketId);
}

class AuthProvider extends GetConnect {
  final tokenEndpoint =
      Uri.parse('${ServiceFinder.services['passport']}/api/auth/token');

  static const clientId = 'solian';
  static const clientSecret = '_F4%q2Eea3';

  static const storage = FlutterSecureStorage();

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['passport'];
    loadCredentials();
  }

  Future<void> refreshCredentials() async {
    final resp = await post('/api/auth/token', {
      'refresh_token': globalCredentials!.refreshToken,
      'grant_type': 'refresh_token',
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }
    globalCredentials = TokenSet(
      accessToken: resp.body['access_token'],
      refreshToken: resp.body['refresh_token'],
      expiredAt: DateTime.now().add(const Duration(minutes: 3)),
    );
    storage.write(
      key: 'auth_credentials',
      value: jsonEncode(globalCredentials!.toJson()),
    );
  }

  Future<Request<T?>> requestAuthenticator<T>(Request<T?> request) async {
    try {
      await ensureCredentials();
      request.headers['Authorization'] = 'Bearer ${globalCredentials!.accessToken}';
    } catch (_) {}

    return request;
  }

  GetConnect configureClient(
    String service, {
    timeout = const Duration(seconds: 5),
  }) {
    final client = GetConnect(
      maxAuthRetries: 3,
      timeout: timeout,
      userAgent: 'Solian/1.1',
      sendUserAgent: true,
    );
    client.httpClient.addAuthenticator(requestAuthenticator);
    client.httpClient.baseUrl = ServiceFinder.services[service];

    return client;
  }

  Future<void> ensureCredentials() async {
    if (!await isAuthorized) throw Exception('unauthorized');
    if (globalCredentials == null) await loadCredentials();

    if (globalCredentials!.isExpired) {
      await refreshCredentials();
      log('Refreshed credentials at ${DateTime.now()}');
    }
  }

  Future<void> loadCredentials() async {
    if (await isAuthorized) {
      final content = await storage.read(key: 'auth_credentials');
      globalCredentials = TokenSet.fromJson(jsonDecode(content!));
    }
  }

  Future<TokenSet> signin(
    BuildContext context,
    String username,
    String password,
  ) async {
    _cachedUserProfileResponse = null;

    final client = ServiceFinder.configureClient('passport');

    // Create ticket
    final resp = await client.post('/api/auth', {
      'username': username,
      'password': password,
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    } else if (resp.body['is_finished'] == false) {
      throw RiskyAuthenticateException(resp.body['ticket']['id']);
    }

    // Assign token
    final tokenResp = await post('/api/auth/token', {
      'code': resp.body['ticket']['grant_token'],
      'grant_type': 'grant_token',
    });
    if (tokenResp.statusCode != 200) {
      throw Exception(tokenResp.bodyString);
    }

    globalCredentials = TokenSet(
      accessToken: tokenResp.body['access_token'],
      refreshToken: tokenResp.body['refresh_token'],
      expiredAt: DateTime.now().add(const Duration(minutes: 3)),
    );

    storage.write(
      key: 'auth_credentials',
      value: jsonEncode(globalCredentials!.toJson()),
    );

    Get.find<AccountProvider>().connect();
    Get.find<AccountProvider>().notifyPrefetch();
    Get.find<ChatProvider>().connect();

    return globalCredentials!;
  }

  void signout() {
    _cachedUserProfileResponse = null;

    Get.find<ChatProvider>().disconnect();
    Get.find<AccountProvider>().disconnect();
    Get.find<AccountProvider>().notifications.clear();
    Get.find<AccountProvider>().notificationUnread.value = 0;

    final chatHistory = ChatEventController();
    chatHistory.initialize().then((_) async {
      await chatHistory.database.localEvents.wipeLocalEvents();
    });

    storage.deleteAll();
  }

  // Data Layer

  Response? _cachedUserProfileResponse;

  Future<bool> get isAuthorized => storage.containsKey(key: 'auth_credentials');

  Future<Response> getProfile({noCache = false}) async {
    if (!noCache && _cachedUserProfileResponse != null) {
      return _cachedUserProfileResponse!;
    }

    final client = configureClient('passport');

    final resp = await client.get('/api/users/me');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    } else {
      _cachedUserProfileResponse = resp;
    }

    return resp;
  }
}
