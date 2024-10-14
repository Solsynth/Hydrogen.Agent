import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/posts/post_replies.dart';

class PostDetailScreen extends StatefulWidget {
  final String id;
  final Post? post;

  const PostDetailScreen({
    super.key,
    required this.id,
    this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isBusy = true;

  Post? _item;

  Future<void> _getDetail() async {
    final PostProvider posts = Get.find();

    try {
      final resp = await posts.getPost(widget.id);
      _item = Post.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e).then((_) => Navigator.pop(context));
    }

    Get.find<LastReadProvider>().feedLastReadAt = _item?.id;

    if (mounted) setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _item = widget.post;
    }
    _getDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy && _item == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: LoadingIndicator(isActive: _isBusy),
        ),
        SliverToBoxAdapter(
          child: PostItem(
            key: ValueKey(_item),
            item: _item!,
            isClickable: false,
            isOverrideEmbedClickable: true,
            isFullDate: true,
            isShowReply: false,
            isContentSelectable: true,
            padding: AppTheme.isLargeScreen(context)
                ? EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  )
                : EdgeInsets.zero,
            onTapMore: () {
              showModalBottomSheet(
                useRootNavigator: true,
                context: context,
                builder: (context) => PostAction(
                  item: _item!,
                  noReact: true,
                ),
              ).then((value) {
                if (value is Future) {
                  value.then((_) {
                    _getDetail();
                  });
                } else if (value != null) {
                  _getDetail();
                }
              });
            },
          ),
        ),
        SliverToBoxAdapter(
          child: const Divider(thickness: 0.3, height: 1).paddingOnly(
            top: 8,
          ),
        ),
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'postReplies'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ).paddingOnly(left: 24, right: 24, top: 16),
          ),
        ),
        PostReplyList(
          item: _item!,
          padding: AppTheme.isLargeScreen(context)
              ? EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                )
              : EdgeInsets.zero,
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom),
        ),
      ],
    );
  }
}
