import 'dart:ui';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/websocket.dart';

FlutterBackgroundService? bgNotificationService;

void autoConfigureBackgroundNotificationService() async {
  if (bgNotificationService != null) return;

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('service_background_notification') != true) return;

  bgNotificationService = FlutterBackgroundService();

  await bgNotificationService!.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundNotificationServiceStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: false,
    ),
    // This feature won't be able to use on iOS
    // We got APNs support covered
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

void autoStartBackgroundNotificationService() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('service_background_notification') != true) return;
  if (bgNotificationService == null) return;
  bgNotificationService!.startService();
}

void autoStopBackgroundNotificationService() async {
  if (bgNotificationService == null) return;
  if (await bgNotificationService!.isRunning()) {
    bgNotificationService?.invoke('stopService');
  }
}

@pragma('vm:entry-point')
void onBackgroundNotificationServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  Get.put(AuthProvider());
  Get.put(WebSocketProvider());

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final auth = Get.find<AuthProvider>();
  await auth.refreshAuthorizeStatus();
  await auth.ensureCredentials();
  if (!auth.isAuthorized.value) {
    debugPrint(
      'Background notification do nothing due to user didn\'t sign in.',
    );
    return;
  }

  const notificationChannelId = 'solian_notification_service';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ws = Get.find<WebSocketProvider>();
  await ws.connect();
  debugPrint('Background notification has been started');
  ws.stream.stream.listen(
    (event) {
      debugPrint(
        'Background notification service incoming message: ${event.method} ${event.message}',
      );

      if (event.method == 'notifications.new' && event.payload != null) {
        final data = Notification.fromJson(event.payload!);
        debugPrint(
          'Background notification service got a notification id=${data.id}',
        );
        flutterLocalNotificationsPlugin.show(
          data.id,
          data.title,
          [data.subtitle, data.body].where((x) => x != null).join('\n'),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Solian Notification Service',
              channelDescription: 'Notifications that sent via Solar Network',
              importance: Importance.high,
              icon: 'mipmap/ic_launcher',
            ),
          ),
        );
      }
    },
  );
}
