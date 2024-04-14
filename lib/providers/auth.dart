import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solian/screens/auth.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:solian/utils/service_url.dart';

class AuthProvider {
  AuthProvider() {
    pickClient();
  }

  final deviceEndpoint =
      getRequestUri('passport', '/api/notifications/subscribe');
  final authorizationEndpoint = getRequestUri('passport', '/auth/o/connect');
  final tokenEndpoint = getRequestUri('passport', '/api/auth/token');
  final userinfoEndpoint = getRequestUri('passport', '/api/users/me');
  final redirectUrl = Uri.parse('solian://auth');

  static const clientId = "solian";
  static const clientSecret = "_F4%q2Eea3";

  static const storage = FlutterSecureStorage();
  static const storageKey = "identity";
  static const profileKey = "profiles";

  oauth2.Client? client;
  DateTime? lastRefreshedAt;

  Future<bool> pickClient() async {
    if (await storage.containsKey(key: storageKey)) {
      try {
        final credentials =
            oauth2.Credentials.fromJson((await storage.read(key: storageKey))!);
        client = oauth2.Client(credentials,
            identifier: clientId, secret: clientSecret);
        await fetchProfiles();
        return true;
      } catch (e) {
        signOff();
        return false;
      }
    } else {
      return false;
    }
  }

  Future<oauth2.Client> createClient(BuildContext context) async {
    // If logged in
    if (await pickClient()) {
      return client!;
    }

    var grant = oauth2.AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
      basicAuth: false,
    );

    var authorizationUrl =
        grant.getAuthorizationUrl(redirectUrl, scopes: ["openid"]);

    var responseUrl = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => AuthorizationScreen(authorizationUrl),
      ),
    );

    var responseUri = Uri.parse(responseUrl);
    return await grant.handleAuthorizationResponse(responseUri.queryParameters);
  }

  Future<void> fetchProfiles() async {
    if (client != null) {
      var userinfo = await client!.get(userinfoEndpoint);
      storage.write(key: profileKey, value: utf8.decode(userinfo.bodyBytes));
    }
  }

  Future<void> refreshToken() async {
    if (client != null) {
      final credentials = await client?.credentials.refresh(
          identifier: clientId, secret: clientSecret, basicAuth: false);
      client = oauth2.Client(credentials!,
          identifier: clientId, secret: clientSecret);
      storage.write(key: storageKey, value: credentials.toJson());
    }
  }

  Future<void> signIn(BuildContext context) async {
    client = await createClient(context);
    storage.write(key: storageKey, value: client!.credentials.toJson());

    await fetchProfiles();
  }

  void signOff() {
    storage.delete(key: profileKey);
    storage.delete(key: storageKey);
  }

  Future<bool> isAuthorized() async {
    const storage = FlutterSecureStorage();
    if (await storage.containsKey(key: storageKey)) {
      if (client != null) {
        if (lastRefreshedAt == null ||
            lastRefreshedAt!
                .add(const Duration(minutes: 3))
                .isBefore(DateTime.now())) {
          await refreshToken();
          lastRefreshedAt = DateTime.now();
        }
      }
      return true;
    } else {
      return false;
    }
  }

  Future<dynamic> getProfiles() async {
    const storage = FlutterSecureStorage();
    return jsonDecode(await storage.read(key: profileKey) ?? "{}");
  }
}
