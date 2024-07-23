import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:solian/widgets/posts/post_list.dart';

class FeedListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, Post> controller;

  const FeedListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Post>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) {
          return SizedContainer(
            child: Builder(
              builder: (context) {
                return PostListEntryWidget(
                  isShowEmbed: isShowEmbed,
                  isNestedClickable: isNestedClickable,
                  isClickable: isClickable,
                  item: item,
                  onUpdate: () {
                    controller.refresh();
                  },
                );
              },
            ),
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}
