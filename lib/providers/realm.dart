import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/services_url.dart';

class RealmProvider with ChangeNotifier {
  List<Realm> realms = List.empty();

  Realm? focusRealm;

  Future<void> fetch(AuthProvider auth) async {
    if (!await auth.isAuthorized()) return;

    var uri = getRequestUri('passport', '/api/realms/me/available');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      realms = result.map((x) => Realm.fromJson(x)).toList();
      notifyListeners();
    } else {
      var message = utf8.decode(res.bodyBytes);
      throw Exception(message);
    }
  }

  Future<Realm> fetchSingle(AuthProvider auth, String alias) async {
    var uri = getRequestUri('passport', '/api/realms/$alias');
    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      focusRealm = Realm.fromJson(result);
      notifyListeners();
      return focusRealm!;
    } else {
      var message = utf8.decode(res.bodyBytes);
      throw Exception(message);
    }
  }

  void clearFocus() {
    focusRealm = null;
    notifyListeners();
  }
}
