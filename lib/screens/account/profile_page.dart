import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:solian/controllers/post_list_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/daily_sign.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/models/subscription.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/providers/subscription.dart';
import 'package:solian/services.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_heading.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/daily_sign/history_chart.dart';
import 'package:solian/widgets/posts/post_list.dart';
import 'package:solian/widgets/posts/post_warped_list.dart';
import 'package:solian/widgets/reports/abuse_report.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:solian/widgets/sized_container.dart';

class AccountProfilePage extends StatefulWidget {
  final String name;

  const AccountProfilePage({super.key, required this.name});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  late final RelationshipProvider _relationshipProvider;
  late final PostListController _postController;
  final PagingController<int, Attachment> _albumPagingController =
      PagingController(firstPageKey: 0);

  bool _isBusy = true;
  bool _isMakingFriend = false;
  bool _isSubscribing = false;
  bool _showMature = false;

  Account? _userinfo;
  Subscription? _subscription;
  Relationship? _relationship;
  List<Post> _pinnedPosts = List.empty();
  List<DailySignRecord> _dailySignRecords = List.empty();
  int _totalUpvote = 0, _totalDownvote = 0;

  Future<void> _getSubscription() async {
    setState(() => _isSubscribing = true);
    _subscription = await Get.find<SubscriptionProvider>()
        .getSubscriptionOnUser(_userinfo!.id);
    setState(() => _isSubscribing = false);
  }

  Future<void> _getRelationship() async {
    setState(() => _isBusy = true);

    final relations = Get.find<RelationshipProvider>();
    _relationship = await relations.getRelationship(_userinfo!.id);

    setState(() => _isBusy = false);
  }

  Future<void> _getUserinfo() async {
    setState(() => _isBusy = true);

    var client = await ServiceFinder.configureClient('id');
    var resp = await client.get('/users/${widget.name}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString).then((_) {
        Navigator.pop(context);
      });
    } else {
      _userinfo = Account.fromJson(resp.body);
    }

    client = await ServiceFinder.configureClient('co');
    resp = await client.get('/users/${widget.name}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString).then((_) {
        Navigator.pop(context);
      });
    } else {
      _totalUpvote = resp.body['total_upvote'];
      _totalDownvote = resp.body['total_downvote'];
    }

    setState(() => _isBusy = false);
  }

  Future<void> _getPinnedPosts() async {
    final client = await ServiceFinder.configureClient('co');
    final resp = await client.get('/users/${widget.name}/pin');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString).then((_) {
        Navigator.pop(context);
      });
    } else {
      setState(() {
        _pinnedPosts =
            resp.body.map((x) => Post.fromJson(x)).toList().cast<Post>();
      });
    }
  }

  Future<void> _getDailySignRecords() async {
    final client = await ServiceFinder.configureClient('id');
    final resp = await client.get('/users/${widget.name}/daily?take=14');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString).then((_) {
        Navigator.pop(context);
      });
    } else {
      final result = PaginationResult.fromJson(resp.body);
      setState(() {
        _dailySignRecords = List.from(
          result.data?.map((x) => DailySignRecord.fromJson(x)) ?? [],
        );
      });
    }
  }

  Future<void> _subscribeToUser() async {
    setState(() => _isSubscribing = true);
    _subscription =
        await Get.find<SubscriptionProvider>().subscribeToUser(_userinfo!.id);
    setState(() => _isSubscribing = false);
  }

  Future<void> _unsubscribeFromUser() async {
    setState(() => _isSubscribing = true);
    await Get.find<SubscriptionProvider>().unsubscribeFromUser(_userinfo!.id);
    _subscription = null;
    setState(() => _isSubscribing = false);
  }

  Future<void> _makeFriend() async {
    setState(() => _isMakingFriend = true);
    try {
      _relationship = await _relationshipProvider.makeFriend(widget.name);
      context.showSnackbar(
        'accountFriendRequestSent'.tr,
      );
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isMakingFriend = false);
    }
  }

  Future<void> _blockUser() async {
    setState(() => _isMakingFriend = true);
    try {
      _relationship = await _relationshipProvider.blockUser(widget.name);
      context.showSnackbar(
        'accountBlocked'.tr,
      );
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isMakingFriend = false);
    }
  }

  Future<void> _unblockUser() async {
    setState(() => _isMakingFriend = true);
    try {
      _relationship =
          await _relationshipProvider.editRelation(_userinfo!.id, 1);
      context.showSnackbar(
        'accountUnblocked'.tr,
      );
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isMakingFriend = false);
    }
  }

  int get _userSocialCreditPoints {
    return _totalUpvote * 2 - _totalDownvote + _postController.postTotal.value;
  }

  @override
  void initState() {
    super.initState();
    _relationshipProvider = Get.find();
    _postController = PostListController(author: widget.name);
    _albumPagingController.addPageRequestListener((pageKey) async {
      final client = await ServiceFinder.configureClient('files');
      final resp = await client.get(
        '/attachments?take=10&offset=$pageKey&author=${widget.name}&original=true',
      );
      if (resp.statusCode == 200) {
        final result = PaginationResult.fromJson(resp.body);
        final out = result.data
            ?.map((e) => Attachment.fromJson(e))
            .where((x) => x.mimetype.split('/').firstOrNull == 'image')
            .toList();
        if (out != null && result.data!.length >= 10) {
          _albumPagingController.appendPage(out, pageKey + out.length);
        } else if (out != null) {
          _albumPagingController.appendLastPage(out);
        }
      } else {
        _albumPagingController.error = resp.bodyString;
      }
    });

    _getUserinfo().then((_) {
      _getRelationship();
      _getSubscription();
      _getPinnedPosts();
      _getDailySignRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _userinfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RootContainer(
      child: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                centerTitle: false,
                floating: true,
                toolbarHeight: AppTheme.toolbarHeight(context),
                leadingWidth: 24,
                automaticallyImplyLeading: false,
                flexibleSpace: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      AppBarLeadingButton.adaptive(context) ?? const Gap(8),
                      const Gap(8),
                      if (_userinfo != null)
                        AccountAvatar(content: _userinfo!.avatar, radius: 16),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_userinfo != null)
                              Text(
                                _userinfo!.nick,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            if (_userinfo != null)
                              Text(
                                '@${_userinfo!.name}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (_userinfo != null && _subscription == null)
                        IconButton(
                          style: const ButtonStyle(
                            visualDensity:
                                VisualDensity(horizontal: -4, vertical: -2),
                          ),
                          onPressed: _isSubscribing ? null : _subscribeToUser,
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'subscribe'.tr,
                        )
                      else if (_userinfo != null)
                        IconButton(
                          style: const ButtonStyle(
                            visualDensity:
                                VisualDensity(horizontal: -4, vertical: -2),
                          ),
                          onPressed:
                              _isSubscribing ? null : _unsubscribeFromUser,
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'unsubscribe'.tr,
                        ),
                      if (_userinfo != null && _relationship == null)
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: _isMakingFriend ? null : _makeFriend,
                          tooltip: 'friendAdd'.tr,
                        )
                      else
                        const IconButton(
                          icon: Icon(Icons.handshake),
                          onPressed: null,
                        ),
                      SizedBox(
                        width: AppTheme.isLargeScreen(context) ? 8 : 16,
                      ),
                    ],
                  ),
                ).paddingOnly(top: MediaQuery.of(context).padding.top),
                bottom: TabBar(
                  tabs: [
                    Tab(text: 'profilePage'.tr),
                    Tab(text: 'profilePosts'.tr),
                    Tab(text: 'profileAlbum'.tr),
                  ],
                ),
              )
            ];
          },
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                children: [
                  CenteredContainer(
                    child: AccountHeadingWidget(
                      name: _userinfo!.name,
                      nick: _userinfo!.nick,
                      desc: _userinfo!.description,
                      badges: _userinfo!.badges,
                      banner: _userinfo!.banner,
                      avatar: _userinfo!.avatar,
                      status: Get.find<StatusProvider>()
                          .getSomeoneStatus(_userinfo!.name),
                      detail: _userinfo,
                      profile: _userinfo!.profile,
                      extraWidgets: [
                        if (_dailySignRecords.isNotEmpty)
                          Card(
                            child: SizedBox(
                              height: 180,
                              width:
                                  max(640, MediaQuery.of(context).size.width),
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      isStrokeCapRound: true,
                                      isStrokeJoinRound: true,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: List.filled(
                                            _dailySignRecords.length,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.3),
                                          ).toList(),
                                        ),
                                      ),
                                      spots: _dailySignRecords
                                          .map(
                                            (x) => FlSpot(
                                              x.createdAt
                                                  .copyWith(
                                                    hour: 0,
                                                    minute: 0,
                                                    second: 0,
                                                    millisecond: 0,
                                                    microsecond: 0,
                                                  )
                                                  .millisecondsSinceEpoch
                                                  .toDouble(),
                                              x.resultTier.toDouble(),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (spots) => spots
                                          .map((spot) => LineTooltipItem(
                                                '${DailySignHistoryChartDialog.signSymbols[spot.y.toInt()]}\n${DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                                                TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ))
                                          .toList(),
                                      getTooltipColor: (_) => Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: 1,
                                        getTitlesWidget: (value, _) => Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            DailySignHistoryChartDialog
                                                .signSymbols[value.toInt()],
                                            textAlign: TextAlign.right,
                                          ).paddingOnly(right: 8),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: 86400000,
                                        getTitlesWidget: (value, _) => Text(
                                          DateFormat('dd').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              value.toInt(),
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                        ).paddingOnly(top: 8),
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ).marginOnly(
                              right: 24,
                              left: 12,
                              bottom: 8,
                              top: 24,
                            ),
                          )
                      ],
                      appendWidgets: [
                        Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            width: double.maxFinite,
                            child: Wrap(
                              alignment: WrapAlignment.spaceAround,
                              children: [
                                TextButton.icon(
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity(
                                      horizontal: -4,
                                      vertical: -2,
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AbuseReportDialog(
                                        resourceId: 'user:${_userinfo!.id}',
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.flag,
                                    size: 16,
                                  ),
                                  label: Text('reportAbuse'.tr),
                                ),
                                if (_relationship?.status != 2)
                                  TextButton.icon(
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -2,
                                      ),
                                    ),
                                    onPressed:
                                        _isMakingFriend ? null : _blockUser,
                                    icon: const Icon(
                                      Icons.block,
                                      size: 16,
                                    ),
                                    label: Text('blockUser'.tr),
                                  )
                                else
                                  TextButton.icon(
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -2,
                                      ),
                                    ),
                                    onPressed:
                                        _isMakingFriend ? null : _unblockUser,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                    ),
                                    label: Text('unblockUser'.tr),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              RefreshIndicator(
                onRefresh: () => Future.wait([
                  _postController.reloadAllOver(),
                  _getPinnedPosts(),
                ]),
                child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatsWidget(
                              'totalSocialCreditPoints'.tr,
                              _userinfo != null
                                  ? _userSocialCreditPoints.toString()
                                  : 0.toString(),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Obx(
                              () => _StatsWidget(
                                'totalPostCount'.tr,
                                _postController.postTotal.value.toString(),
                              ),
                            ),
                            _StatsWidget(
                              'totalUpvote'.tr,
                              _totalUpvote.toString(),
                            ),
                            _StatsWidget(
                              'totalDownvote'.tr,
                              _totalDownvote.toString(),
                            ),
                          ],
                        ),
                      ],
                    ).paddingOnly(top: 16, bottom: 12),
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(thickness: 0.3, height: 0.3),
                  ),
                  SliverList.separated(
                    itemCount: _pinnedPosts.length,
                    itemBuilder: (context, idx) {
                      final element = _pinnedPosts[idx];
                      return Material(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: PostListEntryWidget(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          item: element,
                          isClickable: true,
                          isNestedClickable: true,
                          isShowEmbed: true,
                          showFeaturedReply: true,
                          onUpdate: () {
                            _postController.reloadAllOver();
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, idx) =>
                        const Divider(thickness: 0.3, height: 0.3),
                  ),
                  if (_userinfo == null)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_userinfo != null)
                    PostWarpedListWidget(
                      isPinned: false,
                      controller: _postController.pagingController,
                      onUpdate: () => _postController.reloadAllOver(),
                    ),
                ]),
              ),
              CenteredContainer(
                child: RefreshIndicator(
                  onRefresh: () => Future.sync(
                    () => _albumPagingController.refresh(),
                  ),
                  child: PagedGridView<int, Attachment>(
                    padding: EdgeInsets.zero,
                    pagingController: _albumPagingController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<Attachment>(
                      itemBuilder: (BuildContext context, item, int index) {
                        const radius = BorderRadius.all(Radius.circular(8));
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 0.3,
                            ),
                            borderRadius: radius,
                          ),
                          child: ClipRRect(
                            borderRadius: radius,
                            child: AttachmentListEntry(
                              item: item,
                              isDense: true,
                              parentId: 'album-$index',
                              showMature: _showMature,
                              onReveal: (value) {
                                setState(() => _showMature = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ).paddingAll(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsWidget extends StatelessWidget {
  final String label;
  final String content;

  const _StatsWidget(this.label, this.content);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
