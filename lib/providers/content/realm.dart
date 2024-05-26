import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class RealmProvider extends GetxController {
  Future<Response> listAvailableRealm() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get('/realms/me/available');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
