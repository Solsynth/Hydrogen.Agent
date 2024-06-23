import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/platform.dart';
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
    FirebaseMessaging.instance
        .requestPermission(
            alert: true,
            announcement: true,
            carPlay: true,
            badge: true,
            sound: true)
        .then((status) {
      notifyInitialization();
      notifyPrefetch();
    });

    super.onInit();
  }

  void connect({noRetry = false}) async {
    if (isConnected.value) {
      return;
    } else {
      disconnect();
    }

    final AuthProvider auth = Get.find();
    await auth.ensureCredentials();

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
    websocket = null;
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
        Future.delayed(const Duration(seconds: 1), () => connect());
      },
      onError: (err) {
        isConnected.value = false;
        Future.delayed(const Duration(seconds: 3), () => connect());
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

    final client = auth.configureClient('passport');

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

  Future<void> registerPushNotifications() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    late final String? token;
    late final String provider;
    final deviceUuid = await _getDeviceUuid();

    if (deviceUuid == null || deviceUuid.isEmpty) {
      log("Unable to active push notifications, couldn't get device uuid");
    }

    if (PlatformInfo.isIOS || PlatformInfo.isMacOS) {
      provider = 'apple';
      token = await FirebaseMessaging.instance.getAPNSToken();
    } else {
      provider = 'firebase';
      token = await FirebaseMessaging.instance.getToken();
    }

    final client = auth.configureClient('passport');

    final resp = await client.post('/api/notifications/subscribe', {
      'provider': provider,
      'device_token': token,
      'device_id': deviceUuid,
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }
  }

  Future<String?> _getDeviceUuid() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (PlatformInfo.isWeb) {
      final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      return webInfo.vendor! +
          webInfo.userAgent! +
          webInfo.hardwareConcurrency.toString();
    }
    if (PlatformInfo.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (PlatformInfo.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor!;
    }
    if (PlatformInfo.isLinux) {
      final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId!;
    }
    if (PlatformInfo.isWindows) {
      final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    }
    return null;
  }
}
