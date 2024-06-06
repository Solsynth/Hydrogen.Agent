import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:web_socket_channel/io.dart';

class ChatProvider extends GetxController {
  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;

  IOWebSocketChannel? websocket;

  StreamController<NetworkPackage> stream = StreamController.broadcast();

  void connect({noRetry = false}) async {
    if (isConnected.value) {
      return;
    } else {
      disconnect();
    }

    final AuthProvider auth = Get.find();
    auth.ensureCredentials();

    final uri = Uri.parse(
      '${ServiceFinder.services['messaging']}/api/ws?tk=${auth.credentials!.accessToken}'
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
        stream.sink.add(packet);
      },
      onDone: () {
        isConnected.value = false;
        Future.delayed(const Duration(seconds: 3), () => connect());
      },
      onError: (err) {
        isConnected.value = false;
        Future.delayed(const Duration(seconds: 3), () => connect());
      },
    );
  }
}
