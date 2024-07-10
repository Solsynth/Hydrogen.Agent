import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class FeedProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['interactive'];
  }

  Future<Response> listFeed(int page,
      {int? realm, String? tag, category}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (tag != null) 'tag=$tag',
      if (category != null) 'category=$category',
      if (realm != null) 'realmId=$realm',
    ];
    final resp = await get('/api/feed?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listDraft(int page) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final queries = [
      'take=${10}',
      'offset=$page',
    ];
    final client = auth.configureClient('interactive');
    final resp = await client.get('/api/drafts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listPost(int page, {int? realm}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (realm != null) 'realmId=$realm',
    ];
    final resp = await get('/api/posts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> listPostReplies(String alias, int page) async {
    final resp = await get('/api/posts/$alias/replies?take=${10}&offset=$page');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> getPost(String alias) async {
    final resp = await get('/api/posts/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }

  Future<Response> getArticle(String alias) async {
    final resp = await get('/api/articles/$alias');
    if (resp.statusCode != 200) {
      throw Exception(resp.body);
    }

    return resp;
  }
}
