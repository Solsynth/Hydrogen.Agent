import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/notifications.dart';
import 'package:solian/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketProvider extends GetxController {
  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;

  WebSocketChannel? websocket;

  StreamController<NetworkPackage> stream = StreamController.broadcast();

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
        if (packet.method == 'notifications.new') {
          final NotificationProvider nty = Get.find();
          nty.notifications.add(Notification.fromJson(packet.payload!));
          nty.notificationUnread.value++;
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
}
