import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/content/post.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/post_publish.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/posts/post_list.dart';

class RealmViewScreen extends StatefulWidget {
  final String alias;

  const RealmViewScreen({super.key, required this.alias});

  @override
  State<RealmViewScreen> createState() => _RealmViewScreenState();
}

class _RealmViewScreenState extends State<RealmViewScreen> {
  bool _isBusy = false;
  String? _overrideAlias;

  Realm? _realm;

  getRealm({String? overrideAlias}) async {
    final RealmProvider provider = Get.find();

    setState(() => _isBusy = true);

    if (overrideAlias != null) {
      _overrideAlias = overrideAlias;
    }

    try {
      final resp = await provider.getRealm(_overrideAlias ?? widget.alias);
      setState(() => _realm = Realm.fromJson(resp.body));
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    getRealm();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    title: Text(_realm?.name ?? 'loading'.tr),
                    centerTitle: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          AppRouter.instance
                              .pushNamed(
                            'realmDetail',
                            pathParameters: {'alias': widget.alias},
                            extra: _realm,
                          )
                              .then((value) {
                            if (value == false) AppRouter.instance.pop();
                            if (value != null) {
                              final resp =
                                  Realm.fromJson(value as Map<String, dynamic>);
                              getRealm(overrideAlias: resp.alias);
                            }
                          });
                        },
                      ),
                      SizedBox(
                        width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                      ),
                    ],
                    bottom: const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(icon: Icon(Icons.feed)),
                        Tab(icon: Icon(Icons.chat)),
                      ],
                    ),
                  ),
                )
              ];
            },
            body: Builder(
              builder: (context) {
                if (_isBusy) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  children: [
                    RealmPostListWidget(realm: _realm!),
                    Icon(Icons.directions_transit),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RealmPostListWidget extends StatefulWidget {
  final Realm realm;

  const RealmPostListWidget({super.key, required this.realm});

  @override
  State<RealmPostListWidget> createState() => _RealmPostListWidgetState();
}

class _RealmPostListWidgetState extends State<RealmPostListWidget> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listPost(pageKey, realm: widget.realm.id);
    } catch (e) {
      _pagingController.error = e;
      return;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final parsed = result.data?.map((e) => Post.fromJson(e)).toList();
    if (parsed != null && parsed.length >= 10) {
      _pagingController.appendPage(parsed, pageKey + parsed.length);
    } else if (parsed != null) {
      _pagingController.appendLastPage(parsed);
    }
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(getPosts);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.post_add),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              tileColor: Theme.of(context).colorScheme.surfaceContainer,
              title: Text('postNew'.tr),
              subtitle: Text(
                'postNewInRealmHint'
                    .trParams({'realm': '#${widget.realm.alias}'}),
              ),
              onTap: () {
                AppRouter.instance
                    .pushNamed(
                  'postPublishing',
                  extra: PostPublishingArguments(realm: widget.realm),
                )
                    .then((value) {
                  if (value != null) _pagingController.refresh();
                });
              },
            ),
          ),
          PostListWidget(controller: _pagingController),
        ],
      ),
    );
  }
}
