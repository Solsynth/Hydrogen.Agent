import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/models/notification.dart' as model;
import 'package:web_socket_channel/web_socket_channel.dart';

class NotifyProvider extends ChangeNotifier {
  bool isOpened = false;

  List<model.Notification> notifications = List.empty(growable: true);

  Future<void> fetch(AuthProvider auth) async {
    if (!await auth.isAuthorized()) return;

    var uri = getRequestUri('passport', '/api/notifications?skip=0&take=25');
    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      notifications = result.data?.map((x) => model.Notification.fromJson(x)).toList() ?? List.empty(growable: true);
    }

    notifyListeners();
  }

  Future<WebSocketChannel?> connect(AuthProvider auth) async {
    if (auth.client == null) await auth.pickClient();
    if (!await auth.isAuthorized()) return null;

    await auth.refreshToken();

    var ori = getRequestUri('passport', '/api/notifications/listen');
    var uri = Uri(
      scheme: ori.scheme.replaceFirst('http', 'ws'),
      host: ori.host,
      path: ori.path,
      queryParameters: {'tk': Uri.encodeComponent(auth.client!.credentials.accessToken)},
    );

    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    return channel;
  }

  void onRemoteMessage(model.Notification item) {
    notifications.add(item);
    notifyListeners();
  }

  void clearNonRealtime() {
    notifications = notifications.where((x) => !x.isRealtime).toList();
  }
}
