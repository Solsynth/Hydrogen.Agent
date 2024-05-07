import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:solian/widgets/notification_notifier.dart';
import 'package:solian/widgets/posts/post.dart';

class ExplorePostScreen extends StatelessWidget {
  const ExplorePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      noSafeArea: true,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      appBarActions: const [NotificationButton()],
      title: AppLocalizations.of(context)!.explore,
      child: const ExplorePostWidget(),
    );
  }
}

class ExplorePostWidget extends StatefulWidget {
  final String? realm;

  const ExplorePostWidget({super.key, this.realm});

  @override
  State<ExplorePostWidget> createState() => _ExplorePostWidgetState();
}

class _ExplorePostWidgetState extends State<ExplorePostWidget> {
  final PagingController<int, Post> _pagingController = PagingController(firstPageKey: 0);

  final http.Client _client = http.Client();

  Future<void> fetchFeed(int pageKey) async {
    final offset = pageKey;
    const take = 5;

    Uri uri;
    if (widget.realm == null) {
      uri = getRequestUri('interactive', '/api/feed?take=$take&offset=$offset');
    } else {
      uri = getRequestUri('interactive', '/api/feed?realm=${widget.realm}&take=$take&offset=$offset');
    }

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
                final did = await SolianRouter.router.pushNamed(
                  widget.realm == null ? 'posts.moments.editor' : 'realms.posts.moments.editor',
                  pathParameters: widget.realm == null ? {} : {'realm': widget.realm!},
                );
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
              onTap: () {
                SolianRouter.router.pushNamed(
                  widget.realm == null ? 'posts.details' : 'realms.posts.details',
                  pathParameters: {
                    'alias': item.alias,
                    'dataset': item.dataset,
                    ...(widget.realm == null ? {} : {'realm': widget.realm!}),
                  },
                );
              },
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
