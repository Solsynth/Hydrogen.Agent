import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/feed.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/posts/post_replies.dart';

class PostDetailScreen extends StatefulWidget {
  final String alias;

  const PostDetailScreen({super.key, required this.alias});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? item;

  Future<Post?> getDetail() async {
    final FeedProvider provider = Get.find();

    try {
      final resp = await provider.getPost(widget.alias);
      item = Post.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e).then((_) => Navigator.pop(context));
    }

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
                child: CenteredContainer(
                  child: PostItem(
                    item: item!,
                    isClickable: true,
                    isFullDate: true,
                    isShowReply: false,
                    isContentSelectable: true,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const Divider(thickness: 0.3, height: 1)
                    .paddingOnly(top: 4),
              ),
              SliverToBoxAdapter(
                child: CenteredContainer(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'postReplies'.tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ).paddingOnly(left: 24, right: 24, top: 16),
                  ),
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
