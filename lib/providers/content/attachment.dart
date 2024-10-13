import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exceptions/unauthorized.dart';
import 'package:path/path.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class AttachmentProvider extends GetConnect {
  static Map<String, String> mimetypeOverrides = {
    'mov': 'video/quicktime',
    'mp4': 'video/mp4'
  };

  @override
  void onInit() {
    httpClient.baseUrl = ServiceFinder.buildUrl('files', null);
  }

  final Map<String, Attachment> _cachedResponses = {};

  List<Attachment?> listMetadataFromCache(List<String> rid) {
    if (rid.isEmpty) return List.empty();

    List<Attachment?> result = List.filled(rid.length, null);
    for (var idx = 0; idx < rid.length; idx++) {
      if (_cachedResponses.containsKey(rid[idx])) {
        result[idx] = _cachedResponses[rid[idx]];
      } else {
        result[idx] = null;
      }
    }

    return result;
  }

  Future<List<Attachment?>> listMetadata(
    List<String> rid, {
    noCache = false,
  }) async {
    if (rid.isEmpty) return List.empty();

    List<Attachment?> result = List.filled(rid.length, null);
    List<String> pendingQuery = List.empty(growable: true);
    if (!noCache) {
      for (var idx = 0; idx < rid.length; idx++) {
        if (_cachedResponses.containsKey(rid[idx])) {
          result[idx] = _cachedResponses[rid[idx]];
        } else {
          pendingQuery.add(rid[idx]);
        }
      }
    }

    if (pendingQuery.isNotEmpty) {
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
          _cachedResponses[item.rid] = item;
        }
      }
      for (var i = 0; i < out.length; i++) {
        for (var j = 0; j < rid.length; j++) {
          if (out[i].rid == rid[j]) {
            result[j] = out[i];
          }
        }
      }
    }

    return result;
  }

  Future<Attachment?> getMetadata(String rid, {noCache = false}) async {
    if (!noCache && _cachedResponses.containsKey(rid)) {
      return _cachedResponses[rid]!;
    }

    final resp = await get('/attachments/$rid/meta');
    if (resp.statusCode == 200) {
      final result = Attachment.fromJson(resp.body);
      if (result.destination != 0 && result.isAnalyzed) {
        _cachedResponses[rid] = result;
      }
      return result;
    }

    return null;
  }

  Future<Attachment> createAttachmentDirectly(
    Uint8List data,
    String path,
    String pool,
    Map<String, dynamic>? metadata,
  ) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient(
      'uc',
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
      'pool': pool,
      if (mimetypeOverride != null) 'mimetype': mimetypeOverride,
      'metadata': jsonEncode(metadata),
    });
    final resp = await client.post('/attachments', payload);
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Attachment.fromJson(resp.body);
  }

  Future<AttachmentPlaceholder> createAttachmentMultipartPlaceholder(
    int size,
    String path,
    String pool,
    Map<String, dynamic>? metadata,
  ) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('uc');

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
    final resp = await client.post('/attachments/multipart', {
      'alt': fileAlt,
      'name': basename(path),
      'size': size,
      'pool': pool,
      if (mimetypeOverride != null) 'mimetype': mimetypeOverride,
      'metadata': metadata,
    });
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return AttachmentPlaceholder.fromJson(resp.body);
  }

  Future<Attachment> uploadAttachmentMultipartChunk(
    Uint8List data,
    String name,
    String rid,
    String cid,
  ) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient(
      'uc',
      timeout: const Duration(minutes: 3),
    );

    final payload = FormData({
      'file': MultipartFile(data, filename: name),
    });
    final resp = await client.post('/attachments/multipart/$rid/$cid', payload);
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Attachment.fromJson(resp.body);
  }

  Future<Response> updateAttachment(
    int id,
    String alt, {
    required Map<String, dynamic> metadata,
    bool isMature = false,
  }) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('files');

    var resp = await client.put('/attachments/$id', {
      'alt': alt,
      'metadata': metadata,
      'is_mature': isMature,
    });

    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  Future<Response> deleteAttachment(int id) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) throw const UnauthorizedException();

    final client = await auth.configureClient('files');

    var resp = await client.delete('/attachments/$id');
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return resp;
  }

  void clearCache({String? id}) {
    if (id != null) {
      _cachedResponses.remove(id);
    } else {
      _cachedResponses.clear();
    }
  }
}
