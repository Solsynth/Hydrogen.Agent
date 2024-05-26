import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class ChannelProvider extends GetxController {
  Future<Response> getChannel(String alias, {String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];

    final resp = await client.get('/api/channels/$realm/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> listAvailableChannel({String realm = 'global'}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get('/api/channels/$realm/me/available');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
