import 'dart:async';

import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/models/stickers.dart';
import 'package:solian/services.dart';

class StickerProvider extends GetxController {
  final RxMap<String, FutureOr<Sticker?>> stickerCache = RxMap();

  Future<Sticker?> getStickerByAlias(String alias) {
    if (stickerCache.containsKey(alias)) {
      return Future.value(stickerCache[alias]);
    }

    stickerCache[alias] = Future(() async {
      final client = await ServiceFinder.configureClient('files');
      final resp = await client.get(
        '/stickers/lookup/$alias',
      );
      if (resp.statusCode != 200) {
        if (resp.statusCode == 404) {
          stickerCache[alias] = null;
        }
        throw RequestException(resp);
      }

      return Sticker.fromJson(resp.body);
    }).then((result) {
      stickerCache[alias] = result;
      return result;
    });

    return Future.value(stickerCache[alias]);
  }

  Future<List<Sticker>> searchStickerByAlias(String alias) async {
    final client = await ServiceFinder.configureClient('files');
    final resp = await client.get(
      '/stickers/lookup?probe=$alias',
    );
    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return List<Sticker>.from(resp.body.map((x) => Sticker.fromJson(x)));
  }
}
