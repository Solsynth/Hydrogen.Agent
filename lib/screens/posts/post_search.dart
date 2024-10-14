import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/posts/post_list.dart';

import '../../models/post.dart';

class PostSearchScreen extends StatefulWidget {
  final String? tag;
  final String? category;

  const PostSearchScreen({super.key, this.tag, this.category});

  @override
  State<PostSearchScreen> createState() => _PostSearchScreenState();
}

class _PostSearchScreenState extends State<PostSearchScreen> {
  final TextEditingController _probeController = TextEditingController();
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  late bool _isBusy = widget.tag != null || widget.category != null;

  _searchPosts(int pageKey) async {
    if (widget.tag == null &&
        widget.category == null &&
        _probeController.text.isEmpty) {
      _pagingController.appendLastPage([]);
      return;
    }

    if (!_isBusy) {
      setState(() => _isBusy = true);
    }

    if (pageKey == 0) {
      _pagingController.itemList?.clear();
      _pagingController.nextPageKey = 0;
    }

    final PostProvider provider = Get.find();

    Response resp;
    try {
      if (_probeController.text.isEmpty) {
        resp = await provider.listPost(
          pageKey,
          tag: widget.tag,
          category: widget.category,
        );
      } else {
        resp = await provider.searchPost(
          _probeController.text,
          pageKey,
          tag: widget.tag,
          category: widget.category,
        );
      }
    } catch (e) {
      _pagingController.error = e;
      return;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final parsed = result.data?.map((e) => Post.fromJson(e)).toList();
    if (parsed != null && parsed.length >= 10) {
      _pagingController.appendPage(parsed, pageKey + parsed.length);
    } else if (parsed != null) {
      _pagingController.appendLastPage(parsed);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_searchPosts);
  }

  @override
  void dispose() {
    _probeController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.tag != null)
            ListTile(
              leading: const Icon(Icons.label),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              tileColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withOpacity(0.5),
              title: Text('postSearchWithTag'.trParams({'key': widget.tag!})),
            ),
          if (widget.category != null)
            ListTile(
              leading: const Icon(Icons.category),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              tileColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withOpacity(0.5),
              title: Text('postSearchWithCategory'.trParams({
                'key': widget.category!,
              })),
            ),
          Container(
            color: Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: TextField(
              controller: _probeController,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'search'.tr,
              ),
              onSubmitted: (_) {
                _searchPosts(0);
              },
            ),
          ),
          LoadingIndicator(isActive: _isBusy),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => Future.sync(() => _pagingController.refresh()),
              child: CustomScrollView(
                slivers: [
                  ControlledPostListWidget(
                    controller: _pagingController,
                    onUpdate: () => _pagingController.refresh(),
                  ),
                  SliverGap(MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
