import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/daily_sign.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/daily_sign.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/widgets/posts/post_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebSocketProvider _ws = Get.find();
  late final PostProvider _posts = Get.find();
  late final DailySignProvider _dailySign = Get.find();

  List<Post>? _currentPosts;

  Future<void> _pullPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final resp = await _posts.listRecommendations(0);
    final result = PaginationResult.fromJson(resp.body);
    if (prefs.containsKey('feed_last_read_at')) {
      final id = prefs.getInt('feed_last_read_at')!;
      setState(() {
        _currentPosts = result.data
            ?.map((e) => Post.fromJson(e))
            .where((x) => x.id > id)
            .toList();
      });
    }
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
                ? const Text('诸事不宜')
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
                        'notificationUnreadCount'.trParams({
                          'count': (_currentPosts?.length ?? 0).toString(),
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
                        child: Card(
                          child: PostListEntryWidget(
                            item: item,
                            isClickable: true,
                            isShowEmbed: true,
                            isNestedClickable: true,
                            onUpdate: (_) {
                              _pullPosts();
                            },
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                          ),
                        ),
                      ).paddingSymmetric(horizontal: 8),
                    );
                  },
                ),
              )
            ],
          ),
      ],
    );
  }
}
