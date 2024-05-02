import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:solian/utils/http.dart';
import 'package:solian/utils/service_url.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  final deviceEndpoint = getRequestUri('passport', '/api/notifications/subscribe');
  final tokenEndpoint = getRequestUri('passport', '/api/auth/token');
  final userinfoEndpoint = getRequestUri('passport', '/api/users/me');
  final redirectUrl = Uri.parse('solian://auth');

  static const clientId = 'solian';
  static const clientSecret = '_F4%q2Eea3';

  static const storage = FlutterSecureStorage();
  static const storageKey = 'identity';
  static const profileKey = 'profiles';

  HttpClient? client;

  Future<bool> loadClient() async {
    if (await storage.containsKey(key: storageKey)) {
      try {
        final credentials = oauth2.Credentials.fromJson((await storage.read(key: storageKey))!);
        client = HttpClient(
          defaultToken: credentials.accessToken,
          defaultRefreshToken: credentials.refreshToken,
          onTokenRefreshed: setToken,
        );
        await fetchProfiles();
        return true;
      } catch (e) {
        signoff();
        return false;
      }
    } else {
      return false;
    }
  }

  Future<HttpClient> createClient(BuildContext context, String username, String password) async {
    if (await loadClient()) {
      return client!;
    }

    final credentials = (await oauth2.resourceOwnerPasswordGrant(
      tokenEndpoint,
      username,
      password,
      identifier: clientId,
      secret: clientSecret,
      scopes: ['openid'],
      basicAuth: false,
    ))
        .credentials;

    setToken(credentials.accessToken, credentials.refreshToken!);

    return HttpClient(
      defaultToken: credentials.accessToken,
      defaultRefreshToken: credentials.refreshToken,
      onTokenRefreshed: setToken,
    );
  }

  Future<void> fetchProfiles() async {
    if (client != null) {
      var userinfo = await client!.get(userinfoEndpoint);
      storage.write(key: profileKey, value: utf8.decode(userinfo.bodyBytes));
    }
    notifyListeners();
  }

  Future<void> setToken(String atk, String rtk) async {
    if (client != null) {
      final credentials = oauth2.Credentials(atk, refreshToken: rtk, idToken: atk, scopes: ['openid']);
      storage.write(key: storageKey, value: credentials.toJson());
    }
    notifyListeners();
  }

  Future<void> signin(BuildContext context, String username, String password) async {
    client = await createClient(context, username, password);

    await fetchProfiles();
  }

  void signoff() {
    storage.delete(key: profileKey);
    storage.delete(key: storageKey);
  }

  Future<bool> isAuthorized() async {
    const storage = FlutterSecureStorage();
    return await storage.containsKey(key: storageKey);
  }

  Future<dynamic> getProfiles() async {
    const storage = FlutterSecureStorage();
    return jsonDecode(await storage.read(key: profileKey) ?? '{}');
  }
}
