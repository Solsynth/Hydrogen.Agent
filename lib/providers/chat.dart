import 'dart:async';

import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatProvider {
  bool isOpened = false;

  Future<WebSocketChannel?> connect(AuthProvider auth) async {
    if (auth.client == null) await auth.pickClient();
    if (!await auth.isAuthorized()) return null;

    await auth.refreshToken();

    var ori = getRequestUri('messaging', '/api/unified');
    var uri = Uri(
      scheme: ori.scheme.replaceFirst('http', 'ws'),
      host: ori.host,
      path: ori.path,
      queryParameters: {'tk': Uri.encodeComponent(auth.client!.credentials.accessToken)},
    );

    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    return channel;
  }
}
