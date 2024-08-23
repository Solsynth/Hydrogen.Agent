import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketProvider extends GetxController {
  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;

  RxInt notificationUnread = 0.obs;
  RxList<Notification> notifications =
      List<Notification>.empty(growable: true).obs;

  WebSocketChannel? websocket;

  StreamController<NetworkPackage> stream = StreamController.broadcast();

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
      notifyPrefetch();
    });

    super.onInit();
  }

  Future<void> connect({noRetry = false}) async {
    if (isConnected.value) {
      return;
    } else {
      disconnect();
    }

    final AuthProvider auth = Get.find();

    try {
      await auth.ensureCredentials();

      final uri = Uri.parse(ServiceFinder.buildUrl(
        'dealer',
        '/api/ws?tk=${auth.credentials!.accessToken}',
      ).replaceFirst('http', 'ws'));

      isConnecting.value = true;

      websocket = WebSocketChannel.connect(uri);
      await websocket?.ready;
      listen();

      isConnected.value = true;
    } catch (err) {
      log('Unable connect dealer via websocket... $err');
      if (!noRetry) {
        await auth.refreshCredentials();
        return connect(noRetry: true);
      }
    } finally {
      isConnecting.value = false;
    }
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
        log('Websocket incoming message: ${packet.method} ${packet.message}');
        stream.sink.add(packet);
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

  Future<void> notifyPrefetch() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final client = auth.configureClient('auth');

    final resp = await client.get('/notifications?skip=0&take=100');
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
    if (auth.isAuthorized.isFalse) return;

    late final String? token;
    late final String provider;
    final deviceUuid = await _getDeviceUuid();

    if (deviceUuid == null || deviceUuid.isEmpty) {
      log("Unable to active push notifications, couldn't get device uuid");
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

    final client = auth.configureClient('auth');

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
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (PlatformInfo.isWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      return webInfo.vendor! +
          webInfo.userAgent! +
          webInfo.hardwareConcurrency.toString();
    }
    if (PlatformInfo.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (PlatformInfo.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor!;
    }
    if (PlatformInfo.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId!;
    }
    if (PlatformInfo.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    }
    if (PlatformInfo.isMacOS) {
      final macosInfo = await deviceInfo.macOsInfo;
      return macosInfo.systemGUID;
    }
    return null;
  }
}
