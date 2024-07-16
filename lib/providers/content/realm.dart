import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';

class RealmProvider extends GetxController {
  Future<Response> getRealm(String alias) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient('auth');

    final resp = await client.get('/realms/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> listAvailableRealm() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient('auth');

    final resp = await client.get('/realms/me/available');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
