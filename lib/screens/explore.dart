import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_list_controller.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/navigation/realm_switcher.dart';
import 'package:solian/widgets/posts/post_creation.dart';
import 'package:solian/widgets/posts/post_list.dart';
import 'package:solian/widgets/posts/post_shuffle_swiper.dart';
import 'package:solian/widgets/root_container.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final PostListController _postController;
  late final TabController _tabController;

  List<StreamSubscription>? _subscriptions;

  @override
  void initState() {
    super.initState();
    final navState = Get.find<NavigationStateProvider>();
    _postController = PostListController();
    _postController.realm = navState.focusedRealm.value?.alias;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_postController.mode.value == _tabController.index) return;
      _postController.mode.value = _tabController.index;
      _postController.reloadAllOver();
    });
    _subscriptions = [
      Get.find<NavigationStateProvider>().focusedRealm.listen((value) {
        if (value?.alias != _postController.realm) {
          _postController.realm = value?.alias;
          _postController.reloadAllOver();
        }
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return RootContainer(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final value = await showModalBottomSheet(
              useRootNavigator: true,
              isScrollControlled: true,
              context: context,
              builder: (context) => const PostCreatePopup(),
            );
            if (value is Future) {
              value.then((_) {
                _postController.reloadAllOver();
              });
            } else if (value != null) {
              _postController.reloadAllOver();
            }
          },
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final scrollOffset = constraints.scrollOffset;
                  final colorChangeOffset = 120;

                  final scrollProgress =
                      (scrollOffset / colorChangeOffset).clamp(0.0, 1.0);
                  final blurSigma = lerpDouble(0, 10, scrollProgress) ?? 0;

                  return SliverAppBar(
                    flexibleSpace: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurSigma,
                          sigmaY: blurSigma,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 48,
                              child: const Row(
                                children: [
                                  RealmSwitcher(),
                                ],
                              ).paddingSymmetric(horizontal: 8),
                            ).paddingSymmetric(vertical: 4),
                            TabBar(
                              controller: _tabController,
                              dividerHeight: scrollProgress > 0 ? 0 : 0.3,
                              tabAlignment: TabAlignment.fill,
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.feed, size: 20),
                                      const Gap(8),
                                      Text('postListNews'.tr),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, size: 20),
                                      const Gap(8),
                                      Text('postListFriends'.tr),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shuffle_on_outlined,
                                        size: 20,
                                      ),
                                      const Gap(8),
                                      Text('postListShuffle'.tr),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).paddingOnly(top: MediaQuery.of(context).padding.top),
                      ),
                    ),
                    expandedHeight: 104,
                    snap: true,
                    floating: true,
                    toolbarHeight: AppTheme.toolbarHeight(context),
                    leading: AppBarLeadingButton.adaptive(context),
                    actions: [
                      const BackgroundStateWidget(),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          AppRouter.instance.pushNamed('postSearch');
                        },
                      ),
                      const NotificationButton(),
                      SizedBox(
                        width: AppTheme.isLargeScreen(context) ? 8 : 16,
                      ),
                    ],
                  );
                },
              )
            ];
          },
          body: Obx(() {
            if (_postController.isPreparing.isTrue) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: () => _postController.reloadAllOver(),
                        child: CustomScrollView(slivers: [
                          ControlledPostListWidget(
                            padding: AppTheme.isLargeScreen(context)
                                ? EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  )
                                : EdgeInsets.zero,
                            controller: _postController.pagingController,
                            onUpdate: () => _postController.reloadAllOver(),
                          ),
                        ]),
                      ),
                      Obx(() {
                        if (auth.isAuthorized.value) {
                          return RefreshIndicator(
                            onRefresh: () => _postController.reloadAllOver(),
                            child: CustomScrollView(slivers: [
                              ControlledPostListWidget(
                                padding: AppTheme.isLargeScreen(context)
                                    ? EdgeInsets.symmetric(horizontal: 16)
                                    : EdgeInsets.zero,
                                controller: _postController.pagingController,
                                onUpdate: () => _postController.reloadAllOver(),
                              ),
                            ]),
                          );
                        } else {
                          return SigninRequiredOverlay(
                            onDone: () => _postController.reloadAllOver(),
                          );
                        }
                      }),
                      PostShuffleSwiper(controller: _postController),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    if (_subscriptions != null) {
      for (final subscription in _subscriptions!) {
        subscription.cancel();
      }
    }
    super.dispose();
  }
}
