import 'package:get/get.dart';

abstract class ServiceFinder {
  static const bool devFlag = false;

  static Map<String, String> services = {
    'paperclip':
        devFlag ? 'http://localhost:8443' : 'https://usercontent.solsynth.dev',
    'passport': devFlag ? 'http://localhost:8444' : 'https://id.solsynth.dev',
    'interactive':
        devFlag ? 'http://localhost:8445' : 'https://co.solsynth.dev',
    'messaging': devFlag ? 'http://localhost:8447' : 'https://im.solsynth.dev',
  };

  static GetConnect configureClient(String service,
      {timeout = const Duration(seconds: 5)}) {
    final client = GetConnect(
      timeout: timeout,
      userAgent: 'Solian/1.1',
      sendUserAgent: true,
    );
    client.httpClient.baseUrl = ServiceFinder.services[service];

    return client;
  }
}
