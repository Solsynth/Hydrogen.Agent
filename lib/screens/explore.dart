import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:solian/widgets/posts/item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  final http.Client _client = http.Client();

  Future<void> fetchFeed(int pageKey) async {
    final offset = pageKey;
    const take = 5;

    var uri =
        getRequestUri('interactive', '/api/feed?take=$take&offset=$offset');

    var res = await _client.get(uri);
    if (res.statusCode == 200) {
      final result =
          PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final items =
          result.data?.map((x) => Post.fromJson(x)).toList() ?? List.empty();
      final isLastPage = (result.count - pageKey) < take;
      if (isLastPage || result.data == null) {
        _pagingController.appendLastPage(items);
      } else {
        final nextPageKey = pageKey + items.length;
        _pagingController.appendPage(items, nextPageKey);
      }
    } else {
      _pagingController.error = utf8.decode(res.bodyBytes);
    }
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) => fetchFeed(pageKey));
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      noSafeArea: true,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          final did = await router.pushNamed("posts.moments.new");
          if (did == true) _pagingController.refresh();
        },
      ),
      title: AppLocalizations.of(context)!.explore,
      child: RefreshIndicator(
        onRefresh: () => Future.sync(
          () => _pagingController.refresh(),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: PagedListView<int, Post>.separated(
              pagingController: _pagingController,
              separatorBuilder: (context, index) =>
                  const Divider(thickness: 0.3),
              builderDelegate: PagedChildBuilderDelegate<Post>(
                itemBuilder: (context, item, index) => GestureDetector(
                  child: PostItem(item: item),
                  onTap: () {
                    router.pushNamed(
                      'posts.screen',
                      pathParameters: {
                        'alias': item.alias,
                        'dataset': '${item.modelType}s',
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
