import 'package:get/get.dart';
import 'package:solian/services.dart';

class AttachmentListProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['paperclip'];
  }

  Future<Response> getMetadata(int id) => get('/api/attachments/$id/meta');
}
