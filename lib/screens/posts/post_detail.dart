import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/post.dart';
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
    final PostProvider provider = Get.find();

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

          return ListView(
            children: [
              PostItem(
                item: item!,
                isClickable: true,
                isShowReply: false,
              ),
              const Divider(thickness: 0.3, height: 0.3),
              Text(
                'postReplies'.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ).paddingOnly(left: 24, right: 24, top: 16),
              PostReplyList(
                item: item!,
                shrinkWrap: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
