import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/last_read.dart';
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
  Post? item;

  Future<Post?> getDetail() async {
    if (widget.post != null) {
      item = widget.post;
      Get.find<LastReadProvider>().feedLastReadAt = item?.id;
      return widget.post;
    }

    final PostProvider provider = Get.find();

    try {
      final resp = await provider.getPost(widget.id);
      item = Post.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e).then((_) => Navigator.pop(context));
    }

    Get.find<LastReadProvider>().feedLastReadAt = item?.id;

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder(
        future: getDetail(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PostItem(
                  item: item!,
                  isClickable: false,
                  isOverrideEmbedClickable: true,
                  isFullDate: true,
                  isFullContent: true,
                  isShowReply: false,
                  isContentSelectable: true,
                ),
              ),
              SliverToBoxAdapter(
                child: const Divider(thickness: 0.3, height: 1)
                    .paddingOnly(top: 4),
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
              PostReplyList(item: item!),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom),
              ),
            ],
          );
        },
      ),
    );
  }
}
