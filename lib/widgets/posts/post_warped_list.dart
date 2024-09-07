import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/post_list.dart';

class PostWarpedListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final bool isPinned;
  final PagingController<int, Post> controller;
  final Function? onUpdate;

  const PostWarpedListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
    this.isPinned = true,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Post>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) {
          if (item.pinnedAt != null && !isPinned) {
            return const SizedBox.shrink();
          }
          return PostListEntryWidget(
            renderOrder: index,
            isShowEmbed: isShowEmbed,
            isNestedClickable: isNestedClickable,
            isClickable: isClickable,
            item: item,
            onUpdate: onUpdate ?? () {},
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}
