import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/widgets/posts/post_list.dart';

class PostReplyList extends StatefulWidget {
  final Post item;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const PostReplyList({
    super.key,
    required this.item,
    this.padding,
    this.backgroundColor,
  });

  @override
  State<PostReplyList> createState() => _PostReplyListState();
}

class _PostReplyListState extends State<PostReplyList> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  Future<void> getReplies(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listPostReplies(widget.item.id.toString(), pageKey);
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
  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(getReplies);
  }

  @override
  Widget build(BuildContext context) {
    return PostListWidget(
      padding: widget.padding,
      isShowEmbed: false,
      controller: _pagingController,
      backgroundColor: widget.backgroundColor,
    );
  }
}

class PostReplyListPopup extends StatelessWidget {
  final Post item;

  const PostReplyListPopup({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'postReplies'.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_comment),
              visualDensity: const VisualDensity(horizontal: -4),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        ).paddingOnly(left: 24, right: 24, top: 24, bottom: 8),
        Expanded(
          child: CustomScrollView(
            slivers: [
              PostReplyList(
                item: item,
                padding: EdgeInsets.symmetric(horizontal: 10),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerLow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
