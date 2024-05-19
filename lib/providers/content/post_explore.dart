import 'package:get/get.dart';
import 'package:solian/services.dart';

class PostExploreProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['interactive'];
  }

  Future<Response> listPost(int page) => get('/api/feed?take=${10}&offset=$page');
}
