import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:image/image.dart' as img;

Future<String> calculateBytesSha256(Uint8List data) async {
  Digest digest;
  if (PlatformInfo.isWeb) {
    digest = sha256.convert(data);
  } else {
    digest = await Isolate.run(() => sha256.convert(data));
  }
  return digest.toString();
}

Future<String> calculateFileSha256(File file) async {
  Uint8List bytes;
  if (PlatformInfo.isWeb) {
    bytes = await file.readAsBytes();
  } else {
    bytes = await Isolate.run(() => file.readAsBytesSync());
  }
  return await calculateBytesSha256(bytes);
}

Future<double> calculateDataAspectRatio(Uint8List data) async {
  if (PlatformInfo.isWeb) {
    return 1;
  }
  final decoder = await Isolate.run(() => img.findDecoderForData(data));
  if (decoder == null) return 1;
  final image = await Isolate.run(() => decoder.decode(data));
  if (image == null) return 1;
  return image.width / image.height;
}

Future<double> calculateFileAspectRatio(File file) async {
  if (PlatformInfo.isWeb) {
    return 1;
  }
  final bytes = await Isolate.run(() => file.readAsBytesSync());
  return await calculateDataAspectRatio(bytes);
}

class AttachmentProvider extends GetConnect {
  static Map<String, String> mimetypeOverrides = {
    'mov': 'video/quicktime',
    'mp4': 'video/mp4'
  };

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

  Future<Response> createAttachment(
      Uint8List data, String path, String hash, String usage,
      {double? ratio}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) throw Exception('unauthorized');

    final client = auth.configureClient(
      'paperclip',
      timeout: const Duration(minutes: 3),
    );

    final filePayload = MultipartFile(data, filename: basename(path));
    final fileAlt = basename(path).contains('.')
        ? basename(path).substring(0, basename(path).lastIndexOf('.'))
        : basename(path);
    final fileExt = basename(path)
        .substring(basename(path).lastIndexOf('.') + 1)
        .toLowerCase();

    // Override for some files cannot be detected mimetype by server-side
    String? mimetypeOverride;
    if (mimetypeOverrides.keys.contains(fileExt)) {
      mimetypeOverride = mimetypeOverrides[fileExt];
    }
    final payload = FormData({
      'alt': fileAlt,
      'file': filePayload,
      'hash': hash,
      'usage': usage,
      if (mimetypeOverride != null) 'mimetype': mimetypeOverride,
      'metadata': jsonEncode({
        if (ratio != null) 'ratio': ratio,
      }),
    });
    final resp = await client.post('/api/attachments', payload);
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

    final client = auth.configureClient('paperclip');

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

    final client = auth.configureClient('paperclip');

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
