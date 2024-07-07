import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/content/post.dart';
import 'package:solian/widgets/posts/feed_list.dart';

class FeedSearchScreen extends StatefulWidget {
  final String? tag;
  final String? category;

  const FeedSearchScreen({super.key, this.tag, this.category});

  @override
  State<FeedSearchScreen> createState() => _FeedSearchScreenState();
}

class _FeedSearchScreenState extends State<FeedSearchScreen> {
  final PagingController<int, FeedRecord> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listFeed(
        pageKey,
        tag: widget.tag,
        category: widget.category,
      );
    } catch (e) {
      _pagingController.error = e;
      return;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final parsed = result.data?.map((e) => FeedRecord.fromJson(e)).toList();
    if (parsed != null && parsed.length >= 10) {
      _pagingController.appendPage(parsed, pageKey + parsed.length);
    } else if (parsed != null) {
      _pagingController.appendLastPage(parsed);
    }
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(getPosts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            if (widget.tag != null)
              ListTile(
                leading: const Icon(Icons.label),
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                title: Text('feedSearchWithTag'.trParams({'key': widget.tag!})),
              ),
            if (widget.category != null)
              ListTile(
                leading: const Icon(Icons.category),
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                title: Text('feedSearchWithCategory'.trParams({'key': widget.category!})),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Future.sync(() => _pagingController.refresh()),
                child: CustomScrollView(
                  slivers: [
                    FeedListWidget(controller: _pagingController),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
