import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AccountProvider extends GetxController {
  final FlutterLocalNotificationsPlugin localNotify =
      FlutterLocalNotificationsPlugin();

  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;

  RxInt notificationUnread = 0.obs;
  RxList<Notification> notifications =
      List<Notification>.empty(growable: true).obs;

  IOWebSocketChannel? websocket;

  @override
  onInit() {
    Permission.notification.request().then((status) {
      notifyInitialization();
      notifyPrefetch();
    });

    super.onInit();
  }

  void connect({noRetry = false}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    if (auth.credentials == null) await auth.loadCredentials();

    final uri = Uri.parse(
      '${ServiceFinder.services['passport']}/api/ws?tk=${auth.credentials!.accessToken}'
          .replaceFirst('http', 'ws'),
    );

    isConnecting.value = true;

    try {
      websocket = IOWebSocketChannel.connect(uri);
      await websocket?.ready;
    } catch (e) {
      if (!noRetry) {
        await auth.refreshCredentials();
        return connect(noRetry: true);
      }
    }

    listen();

    isConnected.value = true;
    isConnecting.value = false;
  }

  void disconnect() {
    websocket?.sink.close(WebSocketStatus.normalClosure);
    isConnected.value = false;
  }

  void listen() {
    websocket?.stream.listen(
      (event) {
        final packet = NetworkPackage.fromJson(jsonDecode(event));
        switch (packet.method) {
          case 'notifications.new':
            final notification = Notification.fromJson(packet.payload!);
            notificationUnread++;
            notifications.add(notification);
            notifyMessage(notification.subject, notification.content);
            break;
        }
      },
      onDone: () {
        isConnected.value = false;
      },
      onError: (err) {
        isConnected.value = false;
      },
    );
  }

  void notifyInitialization() {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const darwinSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory('general'),
      ],
    );
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    localNotify.initialize(initializationSettings);
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

  Future<void> notifyPrefetch() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get('/api/notifications?skip=0&take=100');
    if (resp.statusCode == 200) {
      final result = PaginationResult.fromJson(resp.body);
      final data = result.data?.map((x) => Notification.fromJson(x)).toList();
      if (data != null) {
        notifications.addAll(data);
        notificationUnread.value = data.length;
      }
    }
  }
}
