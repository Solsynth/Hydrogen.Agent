import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';

class PostListWidget extends StatelessWidget {
  final bool shrinkWrap;
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, Post> controller;

  const PostListWidget({
    super.key,
    required this.controller,
    this.shrinkWrap = false,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, Post>.separated(
      shrinkWrap: shrinkWrap,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) {
          return GestureDetector(
            child: PostItem(
              key: Key('p${item.alias}'),
              item: item,
              isShowEmbed: isShowEmbed,
              isClickable: isNestedClickable,
            ).paddingSymmetric(
              vertical: (item.attachments?.isEmpty ?? false) ? 8 : 0,
            ),
            onTap: () {
              if (!isClickable) return;
              AppRouter.instance.pushNamed(
                'postDetail',
                pathParameters: {'alias': item.alias},
              );
            },
            onLongPress: () {
              showModalBottomSheet(
                useRootNavigator: true,
                context: context,
                builder: (context) => PostAction(item: item),
              ).then((value) {
                if (value == true) controller.refresh();
              });
            },
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}
