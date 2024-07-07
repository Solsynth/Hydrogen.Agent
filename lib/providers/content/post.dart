import 'package:get/get.dart';
import 'package:solian/services.dart';

class PostProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['interactive'];
  }

  Future<Response> listFeed(int page, {int? realm}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (realm != null) 'realmId=$realm',
    ];
    final resp = await get('/api/feed?${queries.join('&')}');
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
}
