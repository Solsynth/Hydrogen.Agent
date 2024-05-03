import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/screen.dart';
import 'package:solian/utils/service_url.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:solian/widgets/empty.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:solian/widgets/notification_notifier.dart';
import 'package:solian/widgets/posts/post.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Post? _selectedPost;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    return IndentScaffold(
      noSafeArea: true,
      fixedAppBarColor: isLargeScreen,
      appBarActions: const [NotificationButton()],
      title: AppLocalizations.of(context)!.explore,
      child: isLargeScreen
          ? Row(
              children: [
                Flexible(
                  flex: 2,
                  child: ExploreScreenWidget(
                    onSelect: (item) {
                      setState(() => _selectedPost = item);
                    },
                  ),
                ),
                const VerticalDivider(thickness: 0.3, width: 0.3),
                Flexible(
                  flex: 4,
                  child: _selectedPost == null
                      ? const PageEmptyWidget()
                      : PostScreenWidget(
                          key: Key('p${_selectedPost!.id}'),
                          dataset: _selectedPost!.dataset,
                          alias: _selectedPost!.alias,
                        ),
                ),
              ],
            )
          : ExploreScreenWidget(
              onSelect: (item) {
                SolianRouter.router.pushNamed(
                  'posts.screen',
                  pathParameters: {
                    'alias': item.alias,
                    'dataset': item.dataset,
                  },
                );
              },
            ),
    );
  }
}

class ExploreScreenWidget extends StatefulWidget {
  final Function(Post item) onSelect;

  const ExploreScreenWidget({super.key, required this.onSelect});

  @override
  State<ExploreScreenWidget> createState() => _ExploreScreenWidgetState();
}

class _ExploreScreenWidgetState extends State<ExploreScreenWidget> {
  final PagingController<int, Post> _pagingController = PagingController(firstPageKey: 0);

  final http.Client _client = http.Client();

  Future<void> fetchFeed(int pageKey) async {
    final offset = pageKey;
    const take = 5;

    var uri = getRequestUri('interactive', '/api/feed?take=$take&offset=$offset');

    var res = await _client.get(uri);
    if (res.statusCode == 200) {
      final result = PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final items = result.data?.map((x) => Post.fromJson(x)).toList() ?? List.empty();
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
    final auth = context.read<AuthProvider>();

    return Scaffold(
      floatingActionButton: FutureBuilder(
        future: auth.isAuthorized(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.edit),
              onPressed: () async {
                final did = await SolianRouter.router.pushNamed('posts.moments.editor');
                if (did == true) _pagingController.refresh();
              },
            );
          } else {
            return Container();
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(
          () => _pagingController.refresh(),
        ),
        child: PagedListView<int, Post>(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Post>(
            itemBuilder: (context, item, index) => PostItem(
              item: item,
              onUpdate: () => _pagingController.refresh(),
              onTap: () => widget.onSelect(item),
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
