import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/stickers/sticker_uploader.dart';

class StickerScreen extends StatefulWidget {
  const StickerScreen({super.key});

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 0);

  Future<bool?> _promptUploadSticker() {
    return showDialog(
      context: context,
      builder: (context) => const StickerUploadDialog(),
    );
  }

  @override
  void initState() {
    final AuthProvider auth = Get.find();
    final name = auth.userProfile.value!['name'];
    _pagingController.addPageRequestListener((pageKey) async {
      final client = ServiceFinder.configureClient('files');
      final resp =
          await client.get('/stickers?take=10&offset=$pageKey&author=$name');
      if (resp.statusCode == 200) {
        final result = PaginationResult.fromJson(resp.body);
        final out = result.data
            ?.map((e) => e) // TODO transform object
            .toList();
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
            PagedSliverList(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: (BuildContext context, item, int index) {
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
