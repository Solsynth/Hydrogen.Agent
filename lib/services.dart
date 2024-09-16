import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:solian/platform.dart';

abstract class ServiceFinder {
  static const bool devFlag = false;

  static const String dealerUrl =
      devFlag ? 'http://localhost:8442' : 'https://api.sn.solsynth.dev';

  static String buildUrl(String serviceName, String? append) {
    append ??= '';
    if (serviceName == 'dealer') {
      return '$dealerUrl$append';
    }
    return '$dealerUrl/cgi/$serviceName$append';
  }

  static Future<String> getUserAgent() async {
    final String platformInfo;
    if (PlatformInfo.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      platformInfo =
          'Android; ${deviceInfo.brand} ${deviceInfo.model}; ${deviceInfo.id}';
    } else if (PlatformInfo.isIOS) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      platformInfo = 'iOS; ${deviceInfo.model}; ${deviceInfo.name}';
    } else if (PlatformInfo.isMacOS) {
      final deviceInfo = await DeviceInfoPlugin().macOsInfo;
      platformInfo = 'MacOS; ${deviceInfo.model}; ${deviceInfo.hostName}';
    } else if (PlatformInfo.isWindows) {
      final deviceInfo = await DeviceInfoPlugin().windowsInfo;
      platformInfo =
          'Windows NT; ${deviceInfo.productName}; ${deviceInfo.computerName}';
    } else if (PlatformInfo.isLinux) {
      final deviceInfo = await DeviceInfoPlugin().linuxInfo;
      platformInfo = 'Linux; ${deviceInfo.prettyName}';
    } else if (PlatformInfo.isWeb) {
      final deviceInfo = await DeviceInfoPlugin().webBrowserInfo;
      platformInfo = 'Web; ${deviceInfo.vendor}';
    } else {
      platformInfo = 'Unknown';
    }

    final packageInfo = await PackageInfo.fromPlatform();

    return 'Solian/${packageInfo.version}+${packageInfo.buildNumber} ($platformInfo)';
  }

  static Future<GetConnect> configureClient(String serviceName,
      {timeout = const Duration(seconds: 5)}) async {
    final client = GetConnect(
      timeout: timeout,
      userAgent: await getUserAgent(),
      sendUserAgent: true,
    );
    client.httpClient.baseUrl = buildUrl(serviceName, null);

    return client;
  }
}
