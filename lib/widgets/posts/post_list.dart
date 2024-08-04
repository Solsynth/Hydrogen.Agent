import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';

class PostListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, Post> controller;
  final Color? backgroundColor;

  const PostListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Post>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) {
          return PostListEntryWidget(
            isShowEmbed: isShowEmbed,
            isNestedClickable: isNestedClickable,
            isClickable: isClickable,
            item: item,
            backgroundColor: backgroundColor,
            onUpdate: () {
              controller.refresh();
            },
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}

class PostListEntryWidget extends StatelessWidget {
  final int renderOrder;
  final bool isShowEmbed;
  final bool isNestedClickable;
  final bool isClickable;
  final Post item;
  final Function onUpdate;
  final Color? backgroundColor;

  const PostListEntryWidget({
    super.key,
    this.renderOrder = 0,
    required this.isShowEmbed,
    required this.isNestedClickable,
    required this.isClickable,
    required this.item,
    required this.onUpdate,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: PostItem(
        key: Key('p${item.id}'),
        item: item,
        isShowEmbed: isShowEmbed,
        isClickable: isNestedClickable,
        backgroundColor: backgroundColor,
      ).paddingSymmetric(vertical: 8),
      onLongPress: () {
        final AuthProvider auth = Get.find();
        if (auth.isAuthorized.isFalse) return;

        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) => PostAction(item: item),
        ).then((value) {
          if (value is Future) {
            value.then((_) {
              onUpdate();
            });
          } else if (value != null) {
            onUpdate();
          }
        });
      },
    );
  }
}
