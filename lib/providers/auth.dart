import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:solian/models/account.dart';
import 'package:solian/services.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

class AuthProvider extends GetConnect {
  final deviceEndpoint = Uri.parse('/api/notifications/subscribe');
  final tokenEndpoint = Uri.parse('/api/auth/token');
  final userinfoEndpoint = Uri.parse('/api/users/me');
  final redirectUrl = Uri.parse('solian://auth');

  static const clientId = 'solian';
  static const clientSecret = '_F4%q2Eea3';

  static const storage = FlutterSecureStorage();

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['passport'];

    applyAuthenticator();
  }

  oauth2.Credentials? credentials;

  Future<Request<T?>> reqAuthenticator<T>(Request<T?> request) async {
    if (credentials != null && credentials!.isExpired) {
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
      storage.write(key: 'auth_credentials', value: jsonEncode(credentials!.toJson()));
    }

    if (credentials != null) {
      request.headers['Authorization'] = 'Bearer ${credentials!.accessToken}';
    }

    return request;
  }

  void applyAuthenticator() {
    isAuthorized.then((status) async {
      final content = await storage.read(key: 'auth_credentials');
      credentials = oauth2.Credentials.fromJson(jsonDecode(content!));
      if (status) {
        httpClient.addAuthenticator(reqAuthenticator);
      }
    });
  }

  Future<oauth2.Credentials> signin(BuildContext context, String username, String password) async {
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

    storage.write(key: 'auth_credentials', value: jsonEncode(credentials!.toJson()));
    applyAuthenticator();

    return credentials!;
  }

  void signout() {
    storage.deleteAll();
  }

  Future<bool> get isAuthorized => storage.containsKey(key: 'auth_credentials');

  Future<Response<Account>> get profile => get('/api/users/me', decoder: (data) => Account.fromJson(data));
}
