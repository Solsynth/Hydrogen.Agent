import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:dio/dio.dart' as dio;

class AttachmentProvider extends GetConnect {
  static Map<String, String> mimetypeOverrides = {
    'mov': 'video/quicktime',
    'mp4': 'video/mp4'
  };

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.buildUrl('files', null);
  }

  final Map<int, Attachment> _cachedResponses = {};

  Future<List<Attachment?>> listMetadata(
    List<int> id, {
    noCache = false,
  }) async {
    if (id.isEmpty) return List.empty();

    List<Attachment?> result = List.filled(id.length, null);
    List<int> pendingQuery = List.empty(growable: true);
    if (!noCache) {
      for (var idx = 0; idx < id.length; idx++) {
        if (_cachedResponses.containsKey(id[idx])) {
          result[idx] = _cachedResponses[id[idx]];
        } else {
          pendingQuery.add(id[idx]);
        }
      }
    }

    final resp = await get(
      '/attachments?take=${pendingQuery.length}&id=${pendingQuery.join(',')}',
    );
    if (resp.statusCode != 200) return result;

    final rawOut = PaginationResult.fromJson(resp.body);
    if (rawOut.data == null) return result;

    final List<Attachment> out =
        rawOut.data!.map((x) => Attachment.fromJson(x)).toList();
    for (final item in out) {
      if (item.destination != 0 && item.isAnalyzed) {
        _cachedResponses[item.id] = item;
      }
    }
    for (var i = 0; i < out.length; i++) {
      for (var j = 0; j < id.length; j++) {
        if (out[i].id == id[j]) {
          result[j] = out[i];
        }
      }
    }

    return result;
  }

  Future<Attachment?> getMetadata(int id, {noCache = false}) async {
    if (!noCache && _cachedResponses.containsKey(id)) {
      return _cachedResponses[id]!;
    }

    final resp = await get('/attachments/$id/meta');
    if (resp.statusCode == 200) {
      final result = Attachment.fromJson(resp.body);
      if (result.destination != 0 && result.isAnalyzed) {
        _cachedResponses[id] = result;
      }
      return result;
    }

    return null;
  }

  Future<Attachment> createAttachment(
      Uint8List data, String path, String usage, Map<String, dynamic>? metadata,
      {Function(double)? onProgress}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw Exception('unauthorized');

    await auth.ensureCredentials();

    final filePayload =
        dio.MultipartFile.fromBytes(data, filename: basename(path));
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
    final payload = dio.FormData.fromMap({
      'alt': fileAlt,
      'file': filePayload,
      'usage': usage,
      if (mimetypeOverride != null) 'mimetype': mimetypeOverride,
      'metadata': jsonEncode(metadata),
    });
    final resp = await dio.Dio(
      dio.BaseOptions(
        baseUrl: ServiceFinder.buildUrl('files', null),
        headers: {'Authorization': 'Bearer ${auth.credentials!.accessToken}'},
      ),
    ).post(
      '/attachments',
      data: payload,
      onSendProgress: (count, total) {
        if (onProgress != null) onProgress(count / total);
      },
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.data);
    }

    return Attachment.fromJson(resp.data);
  }

  Future<Response> updateAttachment(
    int id,
    String alt,
    String usage, {
    bool isMature = false,
  }) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw Exception('unauthorized');

    final client = auth.configureClient('files');

    var resp = await client.put('/attachments/$id', {
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
    if (auth.isAuthorized.isFalse) throw Exception('unauthorized');

    final client = auth.configureClient('files');

    var resp = await client.delete('/attachments/$id');
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
