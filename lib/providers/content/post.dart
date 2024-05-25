import 'package:get/get.dart';
import 'package:solian/services.dart';

class PostProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['interactive'];
  }

  Future<Response> listPost(int page) async {
    final resp = await get('/api/feed?take=${10}&offset=$page');
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
