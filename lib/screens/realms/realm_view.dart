import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/posts/post_list.dart';
import 'package:solian/widgets/root_container.dart';

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
  final List<Channel> _channels = List.empty(growable: true);

  getRealm({String? overrideAlias}) async {
    final RealmProvider realm = Get.find();

    setState(() => _isBusy = true);

    if (overrideAlias != null) {
      _overrideAlias = overrideAlias;
    }

    try {
      final resp = await realm.getRealm(_overrideAlias ?? widget.alias);
      setState(() => _realm = Realm.fromJson(resp.body));
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  getChannels() async {
    setState(() => _isBusy = true);

    final ChannelProvider channel = Get.find();
    final resp = await channel.listChannel(scope: _realm!.alias);
    final availableResp = await channel.listAvailableChannel(
      scope: _realm!.alias,
    );

    final Set<int> channelIdx = {};

    setState(() {
      _channels.clear();
      _channels.addAll(
        resp.body.map((e) => Channel.fromJson(e)).toList().cast<Channel>(),
      );
      _channels.addAll(availableResp);
      _channels.retainWhere((x) => channelIdx.add(x.id));
    });

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    getRealm().then((_) {
      getChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  leading: AppBarLeadingButton.adaptive(context),
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
                      width: AppTheme.isLargeScreen(context) ? 8 : 16,
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
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  RealmPostListWidget(realm: _realm!),
                  RealmChannelListWidget(
                    realm: _realm!,
                    channels: _channels,
                    onRefresh: () => getChannels(),
                  ),
                ],
              );
            },
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
      resp = await provider.listPost(pageKey, realm: widget.realm.alias);
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
          PostListWidget(controller: _pagingController),
        ],
      ),
    );
  }
}

class RealmChannelListWidget extends StatelessWidget {
  final Realm realm;
  final List<Channel> channels;
  final Future Function() onRefresh;

  const RealmChannelListWidget({
    super.key,
    required this.realm,
    required this.channels,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_box),
            contentPadding: const EdgeInsets.only(left: 32, right: 8),
            tileColor: Theme.of(context).colorScheme.surfaceContainer,
            title: Text('channelNew'.tr),
            subtitle: Text(
              'channelNewInRealmHint'.trParams({'realm': '#${realm.alias}'}),
            ),
            onTap: () {
              AppRouter.instance
                  .pushNamed(
                'channelOrganizing',
                extra: ChannelOrganizeArguments(realm: realm),
              )
                  .then((value) {
                if (value != null) onRefresh();
              });
            },
          ),
          Expanded(
            child: ChannelListWidget(
              channels: channels,
              selfId: auth.userProfile.value!['id'],
            ),
          )
        ],
      ),
    );
  }
}
