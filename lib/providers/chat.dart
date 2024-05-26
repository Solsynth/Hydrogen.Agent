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
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    if (auth.credentials == null) await auth.loadCredentials();

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
      },
      onError: (err) {
        isConnected.value = false;
      },
    );
  }
}
