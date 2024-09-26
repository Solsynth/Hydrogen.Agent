import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/providers/auth.dart';

class RelationshipProvider extends GetxController {
  final RxInt friendRequestCount = 0.obs;

  final RxList<Relationship> _friends = RxList.empty(growable: true);

  Future<void> refreshRelativeList() async {
    final resp = await listRelation();
    final List<Relationship> result = resp.body
        .map((e) => Relationship.fromJson(e))
        .toList()
        .cast<Relationship>();
    _friends.value = result.where((x) => x.status == 1).toList();
    _friends.refresh();
    friendRequestCount.value = result.where((x) => x.status == 0).length;
  }

  bool hasFriend(Account account) {
    final auth = Get.find<AuthProvider>();
    if (auth.userProfile.value!['id'] == account.id) return true;
    return _friends.any((x) => x.relatedId == account.id);
  }

  Future<Relationship?> getRelationship(int relatedId) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    final resp = await client.get('/users/me/relations/$relatedId');
    if (resp.statusCode == 404) {
      return null;
    } else if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Relationship.fromJson(resp.body);
  }

  Future<Response> listRelation() async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    return client.get('/users/me/relations');
  }

  Future<Response> listRelationWithStatus(int status) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    return client.get('/users/me/relations?status=$status');
  }

  Future<Relationship?> blockUser(String username) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    final resp =
        await client.post('/users/me/relations/block?related=$username', {});
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Relationship.fromJson(resp.body);
  }

  Future<Relationship?> makeFriend(String username) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    final resp = await client.post('/users/me/relations?related=$username', {});
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Relationship.fromJson(resp.body);
  }

  Future<Response> handleRelation(
      Relationship relationship, bool doAccept) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    final resp = await client.post(
      '/users/me/relations/${relationship.relatedId}/${doAccept ? 'accept' : 'decline'}',
      {},
    );
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Relationship?> editRelation(int relatedId, int status) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('auth');
    final resp = await client.put(
      '/users/me/relations/$relatedId',
      {'status': status},
    );
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Relationship.fromJson(resp.body);
  }
}
