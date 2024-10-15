import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';

class NotificationProvider extends GetxController {
  RxBool isBusy = false.obs;

  RxInt notificationUnread = 0.obs;
  RxList<Notification> notifications =
      List<Notification>.empty(growable: true).obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotification();
  }

  Future<void> fetchNotification() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final client = await auth.configureClient('auth');

    final resp = await client.get('/notifications?skip=0&take=100');
    if (resp.statusCode == 200) {
      final result = PaginationResult.fromJson(resp.body);
      final data = result.data?.map((x) => Notification.fromJson(x)).toList();
      if (data != null) {
        print(data.map((x) => x.toJson()));
        notifications.addAll(data);
        notificationUnread.value = data.where((x) => x.readAt == null).length;
      }
    }
  }

  Future<void> markAllRead() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    isBusy.value = true;

    final NotificationProvider nty = Get.find();

    List<int> markList = List.empty(growable: true);
    for (final element in nty.notifications) {
      if (element.id <= 0) continue;
      if (element.readAt != null) continue;
      markList.add(element.id);
    }

    if (markList.isNotEmpty) {
      final client = await auth.configureClient('auth');
      await client.put('/notifications/read', {'messages': markList});
    }

    nty.notifications.clear();

    isBusy.value = false;
  }

  Future<void> markOneRead(Notification element, int index) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final NotificationProvider nty = Get.find();

    if (element.id <= 0) {
      nty.notifications.removeAt(index);
      return;
    } else if (element.readAt != null) {
      return;
    }

    isBusy.value = true;

    final client = await auth.configureClient('auth');

    await client.put('/notifications/read/${element.id}', {});

    nty.notifications.removeAt(index);

    isBusy.value = false;
  }

  void requestPermissions() {
    try {
      FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: true,
          carPlay: true,
          badge: true,
          sound: true);
    } catch (_) {
      // When firebase isn't initialized (background service)
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> registerPushNotifications() async {
    if (PlatformInfo.isWeb) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('service_background_notification') == true) {
      log('Background notification service has been enabled, skip register push notifications');
      return;
    }

    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    late final String? token;
    late final String provider;
    var deviceUuid = await _getDeviceUuid();

    if (deviceUuid == null || deviceUuid.isEmpty) {
      log("Unable to active push notifications, couldn't get device uuid");
      return;
    } else {
      log('Device UUID is $deviceUuid');
    }

    if (PlatformInfo.isIOS || PlatformInfo.isMacOS) {
      provider = 'apple';
      token = await FirebaseMessaging.instance.getAPNSToken();
    } else {
      provider = 'firebase';
      token = await FirebaseMessaging.instance.getToken();
    }
    log('Device Push Token is $token');

    final client = await auth.configureClient('auth');

    final resp = await client.post('/notifications/subscribe', {
      'provider': provider,
      'device_token': token,
      'device_id': deviceUuid,
    });
    if (resp.statusCode != 200 && resp.statusCode != 400) {
      throw RequestException(resp);
    }
  }

  Future<String?> _getDeviceUuid() async {
    if (PlatformInfo.isWeb) return null;
    return await FlutterUdid.consistentUdid;
  }
}
