import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/post_editor.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';

class PostListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, Post> controller;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const PostListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Post>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) {
          return Padding(
            padding: padding ?? EdgeInsets.zero,
            child: PostListEntryWidget(
              isShowEmbed: isShowEmbed,
              isNestedClickable: isNestedClickable,
              isClickable: isClickable,
              showFeaturedReply: true,
              item: item,
              backgroundColor: backgroundColor,
              onUpdate: () {
                controller.refresh();
              },
            ),
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}

class PostListEntryWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isNestedClickable;
  final bool isClickable;
  final bool showFeaturedReply;
  final Post item;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final Function onUpdate;

  const PostListEntryWidget({
    super.key,
    required this.isShowEmbed,
    required this.isNestedClickable,
    required this.isClickable,
    required this.showFeaturedReply,
    required this.item,
    this.backgroundColor,
    this.padding,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: PostItem(
        key: Key('p${item.id}'),
        item: item,
        isShowEmbed: isShowEmbed,
        isClickable: isNestedClickable,
        showFeaturedReply: showFeaturedReply,
        padding: padding,
        backgroundColor: backgroundColor,
        onComment: () {
          AppRouter.instance
              .pushNamed(
            'postEditor',
            extra: PostPublishArguments(reply: item),
          )
              .then((value) {
            if (value is Future) {
              value.then((_) {
                onUpdate();
              });
            } else if (value != null) {
              onUpdate();
            }
          });
        },
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

class ControlledPostListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final bool isPinned;
  final PagingController<int, Post> controller;
  final EdgeInsets? padding;
  final Function? onUpdate;

  const ControlledPostListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
    this.isPinned = true,
    this.padding,
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
            isShowEmbed: isShowEmbed,
            isNestedClickable: isNestedClickable,
            isClickable: isClickable,
            showFeaturedReply: true,
            padding: padding,
            item: item,
            onUpdate: onUpdate ?? () {},
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}
