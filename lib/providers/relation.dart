import 'package:get/get.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class RelationshipProvider extends GetConnect {
  @override
  void onInit() {
    final AuthProvider auth = Get.find();

    httpClient.baseUrl = ServiceFinder.buildUrl('auth', null);
    httpClient.addAuthenticator(auth.requestAuthenticator);
  }

  Future<Response> listRelation() => get('/users/me/relations');

  Future<Response> listRelationWithStatus(int status) =>
      get('/users/me/relations?status=$status');

  Future<Response> makeFriend(String username) async {
    final resp = await post('/users/me/relations?related=$username', {});
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> handleRelation(
      Relationship relationship, bool doAccept) async {
    final AuthProvider auth = Get.find();
    final client = auth.configureClient('auth');
    final resp = await client.post(
      '/users/me/relations/${relationship.relatedId}/${doAccept ? 'accept' : 'decline'}',
      {},
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> editRelation(Relationship relationship, int status) async {
    final AuthProvider auth = Get.find();
    final client = auth.configureClient('auth');
    final resp =
        await client.patch('/users/me/relations/${relationship.relatedId}', {
      'status': status,
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
