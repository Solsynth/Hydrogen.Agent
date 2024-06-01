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
  static Map<String, String> mimetypeOverrides = {'mov': 'video/quicktime'};

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.services['paperclip'];
  }

  final Map<int, Response> _cachedResponses = {};

  Future<Response> getMetadata(int id, {noCache = false}) async {
    if (!noCache && _cachedResponses.containsKey(id)) {
      return _cachedResponses[id]!;
    }

    final resp = await get('/api/attachments/$id/meta');
    _cachedResponses[id] = resp;

    return resp;
  }

  Future<Response> createAttachment(File file, String hash, String usage,
      {double? ratio}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final filePayload =
        MultipartFile(await file.readAsBytes(), filename: basename(file.path));
    final fileAlt = basename(file.path).contains('.')
        ? basename(file.path).substring(0, basename(file.path).lastIndexOf('.'))
        : basename(file.path);
    final fileExt = basename(file.path)
        .substring(basename(file.path).lastIndexOf('.') + 1)
        .toLowerCase();

    // Override for some files cannot be detected mimetype by server-side
    String? mimetypeOverride;
    if (mimetypeOverrides.keys.contains(fileExt)) {
      mimetypeOverride = mimetypeOverrides[fileExt];
    }
    final resp = await client.post(
      '/api/attachments',
      FormData({
        'alt': fileAlt,
        'file': filePayload,
        'hash': hash,
        'usage': usage,
        if (mimetypeOverride != null) 'mimetype': mimetypeOverride,
        'metadata': jsonEncode({
          if (ratio != null) 'ratio': ratio,
        }),
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
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

    final client = GetConnect(maxAuthRetries: 3);
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

    return resp;
  }

  Future<Response> deleteAttachment(int id) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    var resp = await client.delete('/api/attachments/$id');
    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    return resp;
  }

  void clearCache({int? id}) {
    if (id != null) {
      _cachedResponses.remove(id);
    } else {
      _cachedResponses.clear();
    }
  }
}
