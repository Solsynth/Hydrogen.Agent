import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solian/models/keypair.dart';
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

  WebSocketChannel? _channel;

  Future<WebSocketChannel?> connect(
    AuthProvider auth, {
    Keypair? Function(String id)? onKexRequest,
    Function(Keypair kp)? onKexProvide,
  }) async {
    if (auth.client == null) await auth.loadClient();
    if (!await auth.isAuthorized()) return null;

    await auth.client!.refreshToken(auth.client!.currentRefreshToken!);

    var ori = getRequestUri('passport', '/api/ws');
    var uri = Uri(
      scheme: ori.scheme.replaceFirst('http', 'ws'),
      host: ori.host,
      port: ori.port,
      path: ori.path,
      queryParameters: {'tk': Uri.encodeComponent(auth.client!.currentToken!)},
    );

    isOpened = true;

    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    _channel!.stream.listen(
      (event) {
        final result = NetworkPackage.fromJson(jsonDecode(event));
        switch (result.method) {
          case 'notifications.new':
            final result = model.Notification.fromJson(jsonDecode(event));
            unreadAmount++;
            notifications.add(result);
            notifyListeners();
            notifyMessage(result.subject, result.content);
            break;
          case 'kex.request':
            if (onKexRequest == null || result.payload == null) break;
            final resp = onKexRequest(result.payload!['keypair_id']);
            if (resp == null) break;
            _channel!.sink.add(jsonEncode(
              NetworkPackage(method: 'kex.provide', payload: {
                'request_id': result.payload!['request_id'],
                'keypair_id': resp.id,
                'public_key': resp.publicKey,
                'algorithm': resp.algorithm,
              }).toJson(),
            ));
            break;
          case 'kex.provide':
            if (onKexProvide == null || result.payload == null) break;
            onKexProvide(Keypair(
              id: result.payload!['keypair_id'],
              algorithm: result.payload?['algorithm'] ?? 'aes',
              publicKey: result.payload!['public_key'],
              privateKey: result.payload?['private_key'],
            ));
            break;
        }
      },
      onError: (_, __) => Future.delayed(const Duration(seconds: 3), () => connect(auth)),
      onDone: () => Future.delayed(const Duration(seconds: 1), () => connect(auth)),
    );

    return _channel!;
  }

  void disconnect() {
    _channel = null;
    isOpened = false;
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

  void clearRealtimeNotifications() {
    notifications = notifications.where((x) => !x.isRealtime).toList();
    notifyListeners();
  }

  void allRead() {
    unreadAmount = 0;
    notifyListeners();
  }
}
