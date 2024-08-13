import 'package:get/get.dart';

abstract class ServiceFinder {
  static const bool devFlag = false;

  static const String dealerUrl =
      devFlag ? 'http://localhost:8442' : 'https://api.sn.solsynth.dev';
  static const String capitalUrl =
      devFlag ? 'http://localhost:8444' : 'https://solsynth.dev';

  static String buildUrl(String serviceName, String? append) {
    append ??= '';
    if (serviceName == 'dealer') {
      return '$dealerUrl$append';
    } else if (serviceName == 'capital') {
      return '$capitalUrl$append';
    }
    return '$dealerUrl/cgi/$serviceName$append';
  }

  static GetConnect configureClient(String serviceName,
      {timeout = const Duration(seconds: 5)}) {
    final client = GetConnect(
      timeout: timeout,
      userAgent: 'Solian/1.1',
      sendUserAgent: true,
    );
    client.httpClient.baseUrl = buildUrl(serviceName, null);

    return client;
  }
}
