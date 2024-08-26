import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:solian/models/link.dart';
import 'package:solian/services.dart';

class LinkExpandController extends GetxController {
  final Map<String, LinkMeta?> _cachedResponse = {};

  Future<LinkMeta?> expandLink(String url) async {
    log('[LinkExpander] Expanding link... $url');
    final target = utf8.fuse(base64).encode(url);
    if (_cachedResponse.containsKey(target)) return _cachedResponse[target];
    final client = ServiceFinder.configureClient('dealer');
    final resp = await client.get('/api/links/$target');
    if (resp.statusCode != 200) {
      log('Unable to expand link ($url), status: ${resp.statusCode}, response: ${resp.body}');
      _cachedResponse[target] = null;
      return null;
    }
    final result = LinkMeta.fromJson(resp.body);
    _cachedResponse[target] = result;
    return result;
  }
}
