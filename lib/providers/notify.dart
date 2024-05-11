import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/services_url.dart';
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
    const androidSettings = AndroidInitializationSettings('app_icon');
    const darwinSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory('general'),
      ],
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    localNotify.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (lkPlatformIs(PlatformType.macOS) || lkPlatformIs(PlatformType.linux)) {
      return;
    }
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

  Future<void> connect(AuthProvider auth) async {
    if (auth.client == null) await auth.loadClient();
    if (!await auth.isAuthorized()) return;

    await auth.client!.refreshToken(auth.client!.currentRefreshToken!);

    var ori = getRequestUri('passport', '/api/ws');
    var uri = Uri(
      scheme: ori.scheme.replaceFirst('http', 'ws'),
      host: ori.host,
      port: ori.port,
      path: ori.path,
      queryParameters: {'tk': Uri.encodeComponent(auth.client!.currentToken!)},
    );

    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    channel.stream.listen(
      (event) {
        final result = NetworkPackage.fromJson(jsonDecode(event));
        switch (result.method) {
          case 'notifications.new':
            final result = model.Notification.fromJson(jsonDecode(event));
            onRemoteMessage(result);
            notifyMessage(result.subject, result.content);
        }
      },
      onError: (_, __) => connect(auth),
      onDone: () => connect(auth),
    );
  }

  void onRemoteMessage(model.Notification item) {
    unreadAmount++;
    notifications.add(item);
    notifyListeners();
  }

  void notifyMessage(String title, String body) {
    const androidSettings = AndroidNotificationDetails(
      'general',
      'General',
      importance: Importance.high,
      priority: Priority.high,
      silent: true,
    );
    const darwinSettings = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentBadge: true,
      presentSound: false,
    );
    const linuxSettings = LinuxNotificationDetails();

    localNotify.show(
      math.max(1, math.Random().nextInt(100000000)),
      title,
      body,
      const NotificationDetails(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      ),
    );
  }

  void clearAt(int index) {
    notifications.removeAt(index);
    notifyListeners();
  }

  void clearRealtime() {
    notifications = notifications.where((x) => !x.isRealtime).toList();
    notifyListeners();
  }

  void allRead() {
    unreadAmount = 0;
    notifyListeners();
  }
}
