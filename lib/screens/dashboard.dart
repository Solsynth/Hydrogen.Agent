import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/daily_sign.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/daily_sign.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/providers/message/adaptor.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/posts/post_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final LastReadProvider _lastRead = Get.find();
  late final WebSocketProvider _ws = Get.find();
  late final PostProvider _posts = Get.find();
  late final DailySignProvider _dailySign = Get.find();

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

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

  Future<void> _pullMessages() async {
    if (_lastRead.messagesLastReadAt == null) return;
    log('[Dashboard] Pulling messages with pivot: ${_lastRead.messagesLastReadAt}');
    final out = await getWhatsNewEvents(_lastRead.messagesLastReadAt!);
    if (out == null) return;
    setState(() {
      _currentMessages = out.$1;
      _currentMessagesCount = out.$2;
    });
  }

  bool _signingDaily = true;
  DailySignRecord? _signRecord;

  Future<void> _pullDaily() async {
    try {
      _signRecord = await _dailySign.getToday();
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _signingDaily = false);
  }

  Future<void> _signDaily() async {
    setState(() => _signingDaily = true);

    try {
      _signRecord = await _dailySign.signToday();
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _signingDaily = false);
  }

  @override
  void initState() {
    super.initState();
    _pullPosts();
    _pullMessages();
    _pullDaily();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('today'.tr, style: Theme.of(context).textTheme.headlineSmall),
            Text(DateFormat('yyyy/MM/dd').format(DateTime.now())),
          ],
        ).paddingOnly(top: 8, left: 18, right: 18, bottom: 12),
        Card(
          child: ListTile(
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
                          style:
                              GoogleFonts.robotoMono(fontSize: 22, height: 1.2),
                        ),
                        Text(
                          DateFormat('yy/MM').format(DateTime.now()),
                          style: GoogleFonts.robotoMono(fontSize: 12),
                        ),
                      ],
                    )
                  : Text(
                      _signRecord!.symbol,
                      style: GoogleFonts.notoSerifHk(fontSize: 20, height: 1),
                    ).paddingSymmetric(horizontal: 9),
            ).paddingOnly(left: 4),
            title: _signRecord == null
                ? const Text('签到')
                : Text(_signRecord!.overviewSuggestion),
            subtitle: _signRecord == null
                ? const Text('今日未拜访佛祖')
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
                      tooltip: '上香求签',
                      icon: const Icon(Icons.local_fire_department),
                      onPressed: _signingDaily ? null : _signDaily,
                    )
                  : const SizedBox(),
            ),
          ),
        ).paddingSymmetric(horizontal: 8),
        const Divider(thickness: 0.3).paddingSymmetric(vertical: 8),
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
                  width: width,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: min(_ws.notifications.length, 3),
                    itemBuilder: (context, idx) {
                      final x = _ws.notifications[idx];
                      return SizedBox(
                        width: width,
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            title: Text(x.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (x.subtitle != null) Text(x.subtitle!),
                                Text(x.body),
                              ],
                            ),
                          ),
                        ).paddingSymmetric(horizontal: 8),
                      );
                    },
                  ),
                )
              else
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    trailing: const Icon(Icons.inbox_outlined),
                    title: Text('notifyEmpty'.tr),
                    subtitle: Text('notifyEmptyCaption'.tr),
                  ),
                ).paddingSymmetric(horizontal: 8),
            ],
          ).paddingOnly(bottom: 12),
        ),
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
                      AppRouter.instance.goNamed('feed');
                    },
                  ),
                ],
              ).paddingOnly(left: 18, right: 18, bottom: 8),
              SizedBox(
                height: 360,
                width: width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentPosts!.length,
                  itemBuilder: (context, idx) {
                    final item = _currentPosts![idx];
                    return SizedBox(
                      width: width,
                      child: Card(
                        child: PostListEntryWidget(
                          item: item,
                          isClickable: true,
                          isShowEmbed: true,
                          isNestedClickable: true,
                          onUpdate: (_) {
                            _pullPosts();
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                        ),
                      ).paddingSymmetric(horizontal: 8),
                    );
                  },
                ),
              )
            ],
          ),
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
                height: 240,
                width: width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentMessages!.length,
                  itemBuilder: (context, idx) {
                    final item = _currentMessages![idx];
                    return SizedBox(
                      width: width,
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
                                backgroundColor: item.channel!.realmId == null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                radius: 20,
                                child: FaIcon(
                                  FontAwesomeIcons.hashtag,
                                  color: item.channel!.realmId == null
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.primary,
                                  size: 16,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              title: Text(item.channel!.name),
                              subtitle: Text(item.channel!.description),
                              onTap: () {
                                AppRouter.instance.pushNamed(
                                  'channelChat',
                                  pathParameters: {
                                    'alias': item.channel!.alias
                                  },
                                  queryParameters: {
                                    if (item.channel!.realmId != null)
                                      'realm': item.channel!.realm!.alias,
                                  },
                                );
                              },
                            ),
                            ChatEvent(item: item).paddingOnly(
                                bottom: 8, top: 16, left: 8, right: 8),
                          ],
                        ),
                      ).paddingSymmetric(horizontal: 8),
                    );
                  },
                ),
              )
            ],
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered by Solar Network',
              style: TextStyle(color: _unFocusColor, fontSize: 12),
            ),
            Text(
              '占卜多少都是玩，人生还得靠自己',
              style: GoogleFonts.notoSerifHk(
                color: _unFocusColor,
                fontSize: 12,
              ),
            )
          ],
        ).paddingAll(8),
      ],
    );
  }
}
