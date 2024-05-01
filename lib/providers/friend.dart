import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';

class FriendProvider extends ChangeNotifier {
  List<Friendship> friends = List.empty();

  Future<void> fetch(AuthProvider auth) async {
    if (!await auth.isAuthorized()) return;

    var uri = getRequestUri('passport', '/api/users/me/friends?status=1');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      friends = result.map((x) => Friendship.fromJson(x)).toList();
      notifyListeners();
    } else {
      var message = utf8.decode(res.bodyBytes);
      throw Exception(message);
    }
  }
}
