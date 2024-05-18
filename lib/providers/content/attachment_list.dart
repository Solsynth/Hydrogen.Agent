import 'package:get/get.dart';
import 'package:solian/services.dart';

class AttachmentListProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['paperclip'];
  }

  Future<Response> getMetadata(String uuid) => get('/api/attachments/$uuid/meta');
}
