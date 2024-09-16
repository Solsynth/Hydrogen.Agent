import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class PostProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.buildUrl('interactive', null);
  }

  Future<Response> seeWhatsNew(int pivot) async {
    GetConnect client;
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.value) {
      client = await auth.configureClient('co');
    } else {
      client = await ServiceFinder.configureClient('co');
    }
    final resp = await client.get('/whats-new?pivot=$pivot');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listRecommendations(int page,
      {String? realm, String? channel}) async {
    GetConnect client;
    final AuthProvider auth = Get.find();
    final queries = [
      'take=${10}',
      'offset=$page',
      if (realm != null) 'realm=$realm',
    ];
    if (auth.isAuthorized.value) {
      client = await auth.configureClient('co');
    } else {
      client = await ServiceFinder.configureClient('co');
    }
    final resp = await client.get(
      channel == null
          ? '/recommendations?${queries.join('&')}'
          : '/recommendations/$channel?${queries.join('&')}',
    );
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listDraft(int page) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final queries = [
      'take=${10}',
      'offset=$page',
    ];
    final client = await auth.configureClient('interactive');
    final resp = await client.get('/posts/drafts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listPost(int page,
      {String? realm, String? author, tag, category}) async {
    final queries = [
      'take=${10}',
      'offset=$page',
      if (tag != null) 'tag=$tag',
      if (category != null) 'category=$category',
      if (author != null) 'author=$author',
      if (realm != null) 'realm=$realm',
    ];
    final resp = await get('/posts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listPostReplies(String alias, int page) async {
    final resp = await get('/posts/$alias/replies?take=${10}&offset=$page');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<List<Post>> listPostFeaturedReply(String alias) async {
    final resp = await get('/posts/$alias/replies/featured');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return List<Post>.from(resp.body.map((x) => Post.fromJson(x)));
  }

  Future<Response> getPost(String alias) async {
    final resp = await get('/posts/$alias');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> getArticle(String alias) async {
    final resp = await get('/articles/$alias');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }
}
