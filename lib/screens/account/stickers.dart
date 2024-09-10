import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/stickers.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/stickers.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/auto_cache_image.dart';
import 'package:solian/widgets/stickers/sticker_uploader.dart';

class StickerScreen extends StatefulWidget {
  const StickerScreen({super.key});

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  final PagingController<int, StickerPack> _pagingController =
      PagingController(firstPageKey: 0);

  Future<bool> _promptDelete(Sticker item, String prefix) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return false;

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('stickerDeletionConfirm'.tr),
        content: Text(
          'stickerDeletionConfirmCaption'.trParams({
            'name': ':${'$prefix${item.alias}'.camelCase}:',
          }),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (confirm != true) return false;

    final client = auth.configureClient('files');
    final resp = await client.delete('/stickers/${item.id}');

    return resp.statusCode == 200;
  }

  Future<bool?> _promptUploadSticker({Sticker? edit}) {
    return showDialog(
      context: context,
      builder: (context) => StickerUploadDialog(
        edit: edit,
      ),
    );
  }

  Widget _buildEmoteEntry(Sticker item, String prefix) {
    final imageUrl = ServiceFinder.buildUrl(
      'files',
      '/attachments/${item.attachment.rid}',
    );
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.textWarpedPlaceholder),
      contentPadding: const EdgeInsets.only(left: 16, right: 14),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              _promptUploadSticker(edit: item).then((value) {
                if (value == true) _pagingController.refresh();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _promptDelete(item, prefix).then((value) {
                if (value == true) _pagingController.refresh();
              });
            },
          ),
        ],
      ),
      leading: AutoCacheImage(
        imageUrl,
        width: 28,
        height: 28,
        noErrorWidget: true,
      ),
    );
  }

  @override
  void initState() {
    final AuthProvider auth = Get.find();
    final name = auth.userProfile.value!['name'];
    _pagingController.addPageRequestListener((pageKey) async {
      final client = ServiceFinder.configureClient('files');
      final resp = await client.get(
        '/stickers/manifest?take=10&offset=$pageKey&author=$name',
      );
      if (resp.statusCode == 200) {
        final result = PaginationResult.fromJson(resp.body);
        final out = result.data?.map((e) => StickerPack.fromJson(e)).toList();
        if (out != null && result.data!.length >= 10) {
          _pagingController.appendPage(out, pageKey + out.length);
        } else if (out != null) {
          _pagingController.appendLastPage(out);
        }
      } else {
        _pagingController.error = resp.bodyString;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    final StickerProvider sticker = Get.find();
    sticker.refreshAvailableStickers();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _promptUploadSticker().then((value) {
            if (value == true) _pagingController.refresh();
          });
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: CustomScrollView(
          slivers: [
            PagedSliverList<int, StickerPack>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: (BuildContext context, item, int index) {
                  return ExpansionTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(item.name),
                        const Gap(6),
                        Badge(
                          label: Text('#${item.id}'),
                        )
                      ],
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: item.stickers?.map((x) {
                          x.pack = item;
                          return _buildEmoteEntry(x, item.prefix);
                        }).toList() ??
                        List.empty(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
