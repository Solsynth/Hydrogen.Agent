import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/providers/content/feed.dart';
import 'package:solian/widgets/articles/article_item.dart';
import 'package:solian/widgets/centered_container.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String alias;

  const ArticleDetailScreen({super.key, required this.alias});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Article? item;

  Future<Article?> getDetail() async {
    final FeedProvider provider = Get.find();

    try {
      final resp = await provider.getArticle(widget.alias);
      item = Article.fromJson(resp.body);
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
                  child: ArticleItem(
                    item: item!,
                    isClickable: true,
                    isFullDate: true,
                    isFullContent: true,
                  ),
                ),
              ),
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
