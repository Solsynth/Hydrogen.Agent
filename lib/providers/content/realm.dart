import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';

class RealmProvider extends GetxController {
  RxBool isLoading = false.obs;
  RxList<Realm> availableRealms = RxList.empty(growable: true);

  Future<void> refreshAvailableRealms() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    isLoading.value = true;
    final resp = await listAvailableRealm();
    isLoading.value = false;

    availableRealms.value =
        resp.body.map((x) => Realm.fromJson(x)).toList().cast<Realm>();
    availableRealms.refresh();
  }

  Future<Response> getRealm(String alias) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = auth.configureClient('auth');

    final resp = await client.get('/realms/$alias');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listAvailableRealm() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = auth.configureClient('auth');

    final resp = await client.get('/realms/me/available');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }
}
