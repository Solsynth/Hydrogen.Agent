import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/models/notification.dart' as model;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math' as math;

class NotifyProvider extends ChangeNotifier {
  bool isOpened = false;
  int unreadAmount = 0;

  List<model.Notification> notifications = List.empty(growable: true);

  final FlutterLocalNotificationsPlugin localNotify = FlutterLocalNotificationsPlugin();

  NotifyProvider() {
    initNotify();
    requestPermissions();
  }

  void initNotify() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open notification'),
    );

    localNotify.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();
  }

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
    unreadAmount++;
    notifications.add(item);
    notifyListeners();
  }

  void notifyMessage(String title, String body) {
    localNotify.show(
      math.max(1, math.Random().nextInt(100000000)),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  void clearAt(int index) {
    notifications.removeAt(index);
    notifyListeners();
  }

  void clearNonRealtime() {
    notifications = notifications.where((x) => !x.isRealtime).toList();
  }

  void allRead() {
    unreadAmount = 0;
    notifyListeners();
  }
}
