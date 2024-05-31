import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/services.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

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

  oauth2.Credentials? credentials;

  Future<void> refreshCredentials() async {
    final resp = await post('/api/auth/token', {
      'refresh_token': credentials!.refreshToken,
      'grant_type': 'refresh_token',
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }
    credentials = oauth2.Credentials(
      resp.body['access_token'],
      refreshToken: resp.body['refresh_token'],
      idToken: resp.body['access_token'],
      tokenEndpoint: tokenEndpoint,
      expiration: DateTime.now().add(const Duration(minutes: 3)),
    );
    storage.write(
      key: 'auth_credentials',
      value: jsonEncode(credentials!.toJson()),
    );
  }

  Future<Request<T?>> requestAuthenticator<T>(Request<T?> request) async {
    if (credentials != null && credentials!.isExpired) {
      refreshCredentials();
    }

    if (credentials != null) {
      request.headers['Authorization'] = 'Bearer ${credentials!.accessToken}';
    }

    return request;
  }

  Future<void> loadCredentials() async {
    if (await isAuthorized) {
      final content = await storage.read(key: 'auth_credentials');
      credentials = oauth2.Credentials.fromJson(jsonDecode(content!));
    }
  }

  Future<oauth2.Credentials> signin(
    BuildContext context,
    String username,
    String password,
  ) async {
    _cacheUserProfileResponse = null;

    final resp = await oauth2.resourceOwnerPasswordGrant(
      tokenEndpoint,
      username,
      password,
      identifier: clientId,
      secret: clientSecret,
      scopes: ['*'],
      basicAuth: false,
    );

    credentials = oauth2.Credentials(
      resp.credentials.accessToken,
      refreshToken: resp.credentials.refreshToken!,
      idToken: resp.credentials.accessToken,
      tokenEndpoint: tokenEndpoint,
      expiration: DateTime.now().add(const Duration(minutes: 3)),
    );

    storage.write(
      key: 'auth_credentials',
      value: jsonEncode(credentials!.toJson()),
    );

    Get.find<AccountProvider>().connect();
    Get.find<AccountProvider>().notifyPrefetch();
    Get.find<ChatProvider>().connect();

    return credentials!;
  }

  void signout() {
    _cacheUserProfileResponse = null;

    Get.find<ChatProvider>().disconnect();
    Get.find<AccountProvider>().disconnect();
    Get.find<AccountProvider>().notifications.clear();
    Get.find<AccountProvider>().notificationUnread.value = 0;

    storage.deleteAll();
  }

  Response? _cacheUserProfileResponse;

  Future<bool> get isAuthorized => storage.containsKey(key: 'auth_credentials');

  Future<Response> getProfile({noCache = false}) async {
    if (!noCache && _cacheUserProfileResponse != null) {
      return _cacheUserProfileResponse!;
    }

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(requestAuthenticator);

    final resp = await client.get('/api/users/me');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    } else {
      _cacheUserProfileResponse = resp;
    }

    return resp;
  }
}
