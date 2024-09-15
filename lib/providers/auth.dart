import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/websocket.dart';
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

class RiskyAuthenticateException implements Exception {
  final int ticketId;

  RiskyAuthenticateException(this.ticketId);
}

class AuthProvider extends GetConnect {
  final tokenEndpoint =
      Uri.parse(ServiceFinder.buildUrl('auth', '/auth/token'));

  static const clientId = 'solian';
  static const clientSecret = '_F4%q2Eea3';

  static const storage = FlutterSecureStorage();

  TokenSet? credentials;

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.buildUrl('auth', null);
    refreshAuthorizeStatus().then((_) {
      loadCredentials();
      refreshUserProfile();
    });
  }

  Completer<void>? _refreshCompleter;

  Future<void> refreshCredentials() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    } else {
      _refreshCompleter = Completer<void>();
    }

    try {
      if (!credentials!.isExpired) return;
      final resp = await post('/auth/token', {
        'refresh_token': credentials!.refreshToken,
        'grant_type': 'refresh_token',
      });
      if (resp.statusCode != 200) {
        throw RequestException(resp);
      }
      credentials = TokenSet(
        accessToken: resp.body['access_token'],
        refreshToken: resp.body['refresh_token'],
        expiredAt: DateTime.now().add(const Duration(minutes: 3)),
      );
      storage.write(
        key: 'auth_credentials',
        value: jsonEncode(credentials!.toJson()),
      );
      _refreshCompleter!.complete();
      log('Refreshed credentials at ${DateTime.now()}');
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Request<T?>> requestAuthenticator<T>(Request<T?> request) async {
    try {
      await ensureCredentials();
      request.headers['Authorization'] = 'Bearer ${credentials!.accessToken}';
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
    client.httpClient.baseUrl = ServiceFinder.buildUrl(service, null);

    return client;
  }

  Future<void> ensureCredentials() async {
    if (isAuthorized.isFalse) throw const UnauthorizedException();
    if (credentials == null) await loadCredentials();

    if (credentials!.isExpired) {
      await refreshCredentials();
    }
  }

  Future<void> loadCredentials() async {
    if (isAuthorized.isTrue) {
      final content = await storage.read(key: 'auth_credentials');
      credentials = TokenSet.fromJson(jsonDecode(content!));
    }
  }

  Future<TokenSet> signin(
    BuildContext context,
    String username,
    String password,
  ) async {
    userProfile.value = null;

    final client = ServiceFinder.configureClient('auth');

    // Create ticket
    final resp = await client.post('/auth', {
      'username': username,
      'password': password,
    });
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    } else if (resp.body['is_finished'] == false) {
      throw RiskyAuthenticateException(resp.body['ticket']['id']);
    }

    // Assign token
    final tokenResp = await post('/auth/token', {
      'code': resp.body['ticket']['grant_token'],
      'grant_type': 'grant_token',
    });
    if (tokenResp.statusCode != 200) {
      throw Exception(tokenResp.bodyString);
    }

    credentials = TokenSet(
      accessToken: tokenResp.body['access_token'],
      refreshToken: tokenResp.body['refresh_token'],
      expiredAt: DateTime.now().add(const Duration(minutes: 3)),
    );

    storage.write(
      key: 'auth_credentials',
      value: jsonEncode(credentials!.toJson()),
    );

    Get.find<WebSocketProvider>().connect();
    Get.find<WebSocketProvider>().notifyPrefetch();

    return credentials!;
  }

  void signout() {
    isAuthorized.value = false;
    userProfile.value = null;

    Get.find<WebSocketProvider>().disconnect();
    Get.find<WebSocketProvider>().notifications.clear();
    Get.find<WebSocketProvider>().notificationUnread.value = 0;

    AppDatabase.removeDatabase();

    storage.deleteAll();
  }

  // Data Layer

  RxBool isAuthorized = false.obs;
  Rx<Map<String, dynamic>?> userProfile = Rx(null);

  Future<void> refreshAuthorizeStatus() async {
    isAuthorized.value = await storage.containsKey(key: 'auth_credentials');
  }

  Future<void> refreshUserProfile() async {
    final client = configureClient('auth');
    final resp = await client.get('/users/me');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    userProfile.value = resp.body;
  }
}
