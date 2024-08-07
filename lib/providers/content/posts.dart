import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class PostProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.buildUrl('interactive', null);
  }

  Future<Response> listRecommendations(int page,
      {int? realm, String? channel}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (realm != null) 'realmId=$realm',
    ];
    final resp = await get(
      channel == null
          ? '/recommendations?${queries.join('&')}'
          : '/recommendations/$channel?${queries.join('&')}',
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listDraft(int page) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw Exception('unauthorized');

    final queries = [
      'take=${10}',
      'offset=$page',
    ];
    final client = auth.configureClient('interactive');
    final resp = await client.get('/posts/drafts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listPost(int page,
      {int? realm, String? author, tag, category}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (tag != null) 'tag=$tag',
      if (category != null) 'category=$category',
      if (author != null) 'author=$author',
      if (realm != null) 'realmId=$realm',
    ];
    final resp = await get('/posts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listPostReplies(String alias, int page) async {
    final resp = await get('/posts/$alias/replies?take=${10}&offset=$page');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> getPost(String alias) async {
    final resp = await get('/posts/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> getArticle(String alias) async {
    final resp = await get('/articles/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }
}
