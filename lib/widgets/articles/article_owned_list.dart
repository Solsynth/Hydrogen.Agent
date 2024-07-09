import 'package:flutter/material.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/widgets/articles/article_item.dart';

class ArticleOwnedListEntry extends StatelessWidget {
  final Article item;
  final Function onTap;

  const ArticleOwnedListEntry({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArticleItem(
              key: Key('a${item.alias}'),
              item: item,
              isClickable: false,
              isReactable: false,
            ),
          ],
        ),
        onTap: () => onTap(),
      ),
    );
  }
}
