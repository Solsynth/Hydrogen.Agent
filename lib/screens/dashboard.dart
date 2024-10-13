import 'dart:developer';
import 'dart:math' hide log;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/daily_sign.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/daily_sign.dart';
import 'package:solian/providers/database/services/messages.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/daily_sign/history_chart.dart';
import 'package:solian/widgets/posts/post_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthProvider _auth = Get.find();
  late final LastReadProvider _lastRead = Get.find();
  late final WebSocketProvider _ws = Get.find();
  late final PostProvider _posts = Get.find();
  late final DailySignProvider _dailySign = Get.find();

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  List<Notification> get _pendingNotifications =>
      List<Notification>.from(_ws.notifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Post>? _currentPosts;
  int? _currentPostsCount;

  Future<void> _pullPosts() async {
    if (_lastRead.feedLastReadAt == null) return;
    log('[Dashboard] Pulling posts with pivot: ${_lastRead.feedLastReadAt}');
    final resp = await _posts.seeWhatsNew(_lastRead.feedLastReadAt!);
    final result = PaginationResult.fromJson(resp.body);
    setState(() {
      _currentPostsCount = result.count;
      _currentPosts = result.data?.map((e) => Post.fromJson(e)).toList();
    });
  }

  List<Event>? _currentMessages;
  int? _currentMessagesCount;

  Map<Channel, List<Event>>? get _currentGroupedMessages =>
      _currentMessages?.groupListsBy((x) => x.channel!);

  Future<void> _pullMessages() async {
    if (_lastRead.messagesLastReadAt == null) return;
    log('[Dashboard] Pulling messages with pivot: ${_lastRead.messagesLastReadAt}');
    final src = Get.find<MessagesFetchingProvider>();
    final out = await src.getWhatsNewEvents(_lastRead.messagesLastReadAt!);
    if (out == null) return;
    if (mounted) {
      setState(() {
        _currentMessages = out.$1;
        _currentMessagesCount = out.$2;
      });
    }
  }

  bool _signingDaily = true;
  DailySignRecord? _signRecord;
  List<DailySignRecord>? _signRecordHistory;

  Future<void> _pullDaily() async {
    try {
      _signRecord = await _dailySign.getToday();
      _dailySign.listLastRecord(14).then((value) {
        if (mounted) {
          setState(() => _signRecordHistory = value);
        }
      });
    } catch (e) {
      context.showErrorDialog(e);
    }

    if (mounted) {
      setState(() => _signingDaily = false);
    }
  }

  Future<void> _signDaily() async {
    setState(() => _signingDaily = true);

    try {
      _signRecord = await _dailySign.signToday();
      _dailySign.listLastRecord(14).then((value) {
        setState(() => _signRecordHistory = value);
      });
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _signingDaily = false);
  }

  Future<void> _pullData() async {
    if (!_auth.isAuthorized.value) return;
    await Future.wait([
      _pullPosts(),
      _pullMessages(),
      _pullDaily(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _pullData();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _pullData,
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTime.now().day == DateTime.now().toUtc().day
                    ? 'today'.tr
                    : 'yesterday'.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(DateFormat('yyyy/MM/dd').format(DateTime.now().toUtc())),
            ],
          ).paddingOnly(top: 16, left: 18, right: 18, bottom: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: AnimatedSwitcher(
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _signRecord == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd').format(DateTime.now()),
                                style: GoogleFonts.robotoMono(
                                    fontSize: 22, height: 1.2),
                              ),
                              Text(
                                DateFormat('yy/MM').format(DateTime.now()),
                                style: GoogleFonts.robotoMono(fontSize: 12),
                              ),
                            ],
                          )
                        : Text(
                            _signRecord!.symbol,
                            style: GoogleFonts.notoSerifHk(
                                fontSize: 20, height: 1),
                          ).paddingSymmetric(horizontal: 9),
                  ).paddingOnly(left: 4),
                  title: _signRecord == null
                      ? Text('dailySign'.tr)
                      : Text(_signRecord!.overviewSuggestion),
                  subtitle: _signRecord == null
                      ? Text('dailySignNone'.tr)
                      : Text('+${_signRecord!.resultExperience} EXP'),
                  trailing: AnimatedSwitcher(
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _signRecord == null
                        ? IconButton(
                            tooltip: 'dailySignAction'.tr,
                            icon: const Icon(Icons.local_fire_department),
                            onPressed: _signingDaily ? null : _signDaily,
                          )
                        : (_signRecordHistory?.isEmpty ?? true)
                            ? const SizedBox.shrink()
                            : IconButton(
                                tooltip: 'dailySignHistoryAction'.tr,
                                icon: const Icon(Icons.history),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    useRootNavigator: true,
                                    builder: (context) =>
                                        DailySignHistoryChartDialog(
                                      data: _signRecordHistory,
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ).paddingSymmetric(horizontal: 8),
          const Divider(thickness: 0.3).paddingSymmetric(vertical: 8),

          /// Unread notifications
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notification'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 18),
                        ),
                        Text(
                          'notificationUnreadCount'.trParams({
                            'count': _ws.notifications.length.toString(),
                          }),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const NotificationScreen(),
                        ).then((_) => _ws.notificationUnread.value = 0);
                      },
                    ),
                  ],
                ).paddingOnly(left: 18, right: 18, bottom: 8),
                if (_ws.notifications.isNotEmpty)
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: min(_pendingNotifications.length, 10),
                      itemBuilder: (context, idx) {
                        final x = _pendingNotifications[idx];
                        return SizedBox(
                          width: min(360, width),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              title: Text(
                                x.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (x.subtitle != null)
                                    Text(
                                      x.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else
                                    Text(
                                      x.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Gap(4),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 24, right: 32),
                      trailing: const Icon(Icons.inbox_outlined),
                      title: Text('notifyEmpty'.tr),
                      subtitle: Text('notifyEmptyCaption'.tr),
                    ),
                  ).paddingSymmetric(horizontal: 8),
              ],
            ).paddingOnly(bottom: 12),
          ),

          /// Unread friends / followed people posts
          if (_currentPosts?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'feed'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 18),
                        ),
                        Text(
                          'feedUnreadCount'.trParams({
                            'count': (_currentPostsCount ?? 0).toString(),
                          }),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        AppRouter.instance.goNamed('explore');
                      },
                    ),
                  ],
                ).paddingOnly(left: 18, right: 18, bottom: 8),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentPosts!.length,
                    itemBuilder: (context, idx) {
                      final item = _currentPosts![idx];
                      return SizedBox(
                        width: min(480, width),
                        child: Card(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: PostListEntryWidget(
                                item: item,
                                isClickable: true,
                                isShowEmbed: true,
                                isNestedClickable: true,
                                showFeaturedReply: true,
                                onUpdate: (_) {
                                  _pullPosts();
                                },
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                              ),
                            ),
                          ),
                        ).paddingSymmetric(horizontal: 8),
                      );
                    },
                  ),
                )
              ],
            ).paddingOnly(bottom: 12),

          /// Unread messages part
          if (_currentMessages?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'messages'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 18),
                        ),
                        Text(
                          'messagesUnreadCount'.trParams({
                            'count': (_currentMessagesCount ?? 0).toString(),
                          }),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        AppRouter.instance.goNamed('chat');
                      },
                    ),
                  ],
                ).paddingOnly(left: 18, right: 18, bottom: 8),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentGroupedMessages!.length,
                    itemBuilder: (context, idx) {
                      final channel =
                          _currentGroupedMessages!.keys.elementAt(idx);
                      final itemList =
                          _currentGroupedMessages!.values.elementAt(idx);
                      return SizedBox(
                        width: min(520, width),
                        child: Card(
                          child: Column(
                            children: [
                              ListTile(
                                tileColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                )),
                                leading: CircleAvatar(
                                  backgroundColor: channel.realmId == null
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  radius: 20,
                                  child: FaIcon(
                                    FontAwesomeIcons.hashtag,
                                    color: channel.realmId == null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(channel.name),
                                subtitle: Text(channel.description),
                                onTap: () {
                                  AppRouter.instance.pushNamed(
                                    'channelChat',
                                    pathParameters: {'alias': channel.alias},
                                    queryParameters: {
                                      if (channel.realmId != null)
                                        'realm': channel.realm!.alias,
                                    },
                                  );
                                },
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: itemList.length,
                                  itemBuilder: (context, idx) {
                                    final item = itemList[idx];
                                    return ChatEvent(item: item).paddingOnly(
                                        bottom: 8, top: 16, left: 8, right: 8);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ).paddingSymmetric(horizontal: 8),
                      );
                    },
                  ),
                )
              ],
            ).paddingOnly(bottom: 12),

          /// Footer
          Column(
            mainAxisAlignment: AppTheme.isLargeScreen(context)
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Text(
                'Powered by Solar Network',
                style: TextStyle(color: _unFocusColor, fontSize: 12),
              ),
              Text(
                'dashboardFooter'.tr,
                style: TextStyle(color: _unFocusColor, fontSize: 12),
              )
            ],
          ).paddingOnly(left: 8, right: 8, top: 8, bottom: 50),
        ],
      ),
    );
  }
}
