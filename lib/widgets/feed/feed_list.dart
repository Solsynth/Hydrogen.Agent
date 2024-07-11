import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/articles/article_list.dart';
import 'package:solian/widgets/centered_container.dart';
import 'package:solian/widgets/posts/post_list.dart';

class FeedListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, FeedRecord> controller;

  const FeedListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, FeedRecord>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<FeedRecord>(
        itemBuilder: (context, item, index) {
          return CenteredContainer(
            child: Builder(
              builder: (context) {
                switch (item.type) {
                  case 'post':
                    final data = Post.fromJson(item.data);
                    return PostListEntryWidget(
                      isShowEmbed: isShowEmbed,
                      isNestedClickable: isNestedClickable,
                      isClickable: isClickable,
                      item: data,
                      onUpdate: () {
                        controller.refresh();
                      },
                    );
                  case 'article':
                    final data = Article.fromJson(item.data);
                    return ArticleListEntryWidget(
                      isClickable: isClickable,
                      item: data,
                      onUpdate: () {
                        controller.refresh();
                      },
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
          );
        },
      ),
      separatorBuilder: (_, __) => const Divider(thickness: 0.3, height: 0.3),
    );
  }
}
