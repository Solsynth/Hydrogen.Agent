import 'package:get/get.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class FriendProvider extends GetConnect {
  @override
  void onInit() {
    final AuthProvider auth = Get.find();

    httpClient.baseUrl = ServiceFinder.buildUrl('auth', null);
    httpClient.addAuthenticator(auth.requestAuthenticator);
  }

  Future<Response> listFriendship() => get('/users/me/friends');

  Future<Response> listFriendshipWithStatus(int status) =>
      get('/users/me/friends?status=$status');

  Future<Response> createFriendship(String username) async {
    final resp = await post('/users/me/friends?related=$username', {});
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  Future<Response> updateFriendship(Friendship relationship, int status) async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    final otherside = relationship.getOtherside(prof.body['id']);

    final resp = await put('/users/me/friends/${otherside.id}', {
      'status': status,
    });
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}
