import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';

class PostProvider extends GetxController {
  Future<Response> seeWhatsNew(int pivot) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp = await client.get('/whats-new?pivot=$pivot');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listRecommendations(int page,
      {String? realm, String? channel, int take = 10}) async {
    final queries = [
      'take=$take',
      'offset=$page',
      if (realm != null) 'realm=$realm',
    ];
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('interactive');
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
      'truncate=false',
    ];
    final client = await auth.configureClient('interactive');
    final resp = await client.get(
      '/posts/drafts?${queries.join('&')}',
    );
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> searchPost(String probe, int page,
      {String? realm, String? author, tag, category, int take = 10}) async {
    final queries = [
      'probe=$probe',
      'take=$take',
      'offset=$page',
      if (tag != null) 'tag=$tag',
      if (category != null) 'category=$category',
      if (author != null) 'author=$author',
      if (realm != null) 'realm=$realm',
    ];
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp = await client.get('/posts/search?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listPost(int page,
      {String? realm, String? author, tag, category, int take = 10}) async {
    final queries = [
      'take=$take',
      'offset=$page',
      if (tag != null) 'tag=$tag',
      if (category != null) 'category=$category',
      if (author != null) 'author=$author',
      if (realm != null) 'realm=$realm',
    ];
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp = await client.get('/posts?${queries.join('&')}');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> listPostReplies(String alias, int page) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp =
        await client.get('/posts/$alias/replies?take=${10}&offset=$page');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<List<Post>> listPostFeaturedReply(String alias, {int take = 1}) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp = await client.get('/posts/$alias/replies/featured?take=$take');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return List<Post>.from(resp.body.map((x) => Post.fromJson(x)));
  }

  Future<Response> getPost(String alias) async {
    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('co');
    final resp = await client.get('/posts/$alias');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }
}
