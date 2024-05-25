import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:image/image.dart' as img;

Future<String> calculateFileSha256(File file) async {
  final bytes = await Isolate.run(() => file.readAsBytesSync());
  final digest = await Isolate.run(() => sha256.convert(bytes));
  return digest.toString();
}

Future<double> calculateFileAspectRatio(File file) async {
  final bytes = await Isolate.run(() => file.readAsBytesSync());
  final decoder = await Isolate.run(() => img.findDecoderForData(bytes));
  if (decoder == null) return 1;
  final image = await Isolate.run(() => decoder.decode(bytes));
  if (image == null) return 1;
  return image.width / image.height;
}

class AttachmentProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['paperclip'];
  }

  Future<Response> getMetadata(int id) => get('/api/attachments/$id/meta');

  Future<Response> createAttachment(File file, String hash, String usage,
      {double? ratio}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final filePayload =
        MultipartFile(await file.readAsBytes(), filename: basename(file.path));
    final fileAlt = basename(file.path).contains('.')
        ? basename(file.path).substring(0, basename(file.path).lastIndexOf('.'))
        : basename(file.path);

    final resp = await client.post(
      '/api/attachments',
      FormData({
        'alt': fileAlt,
        'file': filePayload,
        'hash': hash,
        'usage': usage,
        'metadata': jsonEncode({
          if (ratio != null) 'ratio': ratio,
        }),
      }),
    );
    if (resp.statusCode == 200) {
      return resp;
    }

    throw Exception(resp.bodyString);
  }

  Future<Response> updateAttachment(
    int id,
    String alt,
    String usage, {
    double? ratio,
    bool isMature = false,
  }) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    var resp = await client.put('/api/attachments/$id', {
      'metadata': {
        if (ratio != null) 'ratio': ratio,
      },
      'alt': alt,
      'usage': usage,
      'is_mature': isMature,
    });

    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp.body;
  }

  Future<Response> deleteAttachment(int id) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    var resp = await client.delete('/api/attachments/$id');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }
}