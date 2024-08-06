import 'package:get/get.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/stickers.dart';
import 'package:solian/services.dart';

class StickerProvider extends GetxController {
  final RxMap<String, String> aliasImageMapping = RxMap();
  final RxList<Sticker> availableStickers = RxList.empty(growable: true);

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
          aliasImageMapping['${pack.prefix}${sticker.alias}'.camelCase!] =
              sticker.imageUrl;
          availableStickers.add(sticker);
        }
      }
    }
    availableStickers.refresh();
  }
}
