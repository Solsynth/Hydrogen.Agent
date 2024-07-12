import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/articles/article_action.dart';
import 'package:solian/widgets/articles/article_item.dart';
import 'package:solian/widgets/sized_container.dart';

class ArticleListWidget extends StatelessWidget {
  final bool isShowEmbed;
  final bool isClickable;
  final bool isNestedClickable;
  final PagingController<int, Article> controller;

  const ArticleListWidget({
    super.key,
    required this.controller,
    this.isShowEmbed = true,
    this.isClickable = true,
    this.isNestedClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Article>.separated(
      addRepaintBoundaries: true,
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Article>(
        itemBuilder: (context, item, index) {
          return CenteredContainer(
            child: ArticleListEntryWidget(
              isClickable: isClickable,
              item: item,
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

class ArticleListEntryWidget extends StatelessWidget {
  final bool isClickable;
  final Article item;
  final Function onUpdate;

  const ArticleListEntryWidget({
    super.key,
    required this.isClickable,
    required this.item,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ArticleItem(
        key: Key('a${item.alias}'),
        item: item,
      ).paddingSymmetric(vertical: 8),
      onTap: () {
        if (!isClickable) return;
        AppRouter.instance.pushNamed(
          'articleDetail',
          pathParameters: {'alias': item.alias},
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) => ArticleAction(item: item),
        ).then((value) {
          if (value != null) onUpdate();
        });
      },
    );
  }
}
