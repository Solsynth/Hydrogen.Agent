import 'package:get/get.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/stickers.dart';
import 'package:solian/services.dart';

class StickerProvider extends GetxController {
  final RxMap<String, String> aliasImageMapping = RxMap();
  final RxMap<String, List<Sticker>> availableStickers = RxMap();

  Future<void> refreshAvailableStickers() async {
    final client = ServiceFinder.configureClient('files');
    final resp = await client.get(
      '/stickers/manifest?take=100',
    );
    if (resp.statusCode == 200) {
      final result = PaginationResult.fromJson(resp.body);
      final out = result.data?.map((e) => StickerPack.fromJson(e)).toList();
      if (out == null) return;

      for (final pack in out) {
        for (final sticker in (pack.stickers ?? List<Sticker>.empty())) {
          sticker.pack = pack;
          final imageUrl = ServiceFinder.buildUrl(
            'files',
            '/attachments/${sticker.attachmentId}',
          );
          aliasImageMapping['${pack.prefix}${sticker.alias}'.camelCase!] =
              imageUrl;
          if (availableStickers[pack.prefix] == null) {
            availableStickers[pack.prefix] = List.empty(growable: true);
          }
          availableStickers[pack.prefix]!.add(sticker);
        }
      }
    }
    availableStickers.refresh();
  }
}
