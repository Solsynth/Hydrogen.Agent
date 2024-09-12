import 'dart:async';

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
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/posts/post_shuffle_swiper.dart';
import 'package:solian/widgets/posts/post_warped_list.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
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
    final NavigationStateProvider navState = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
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
              SliverAppBar(
                title: AppBarTitle('feed'.tr),
                centerTitle: false,
                floating: true,
                toolbarHeight: SolianTheme.toolbarHeight(context),
                leading: AppBarLeadingButton.adaptive(context),
                actions: [
                  const BackgroundStateWidget(),
                  const NotificationButton(),
                  SizedBox(
                    width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'postListNews'.tr),
                    Tab(text: 'postListFriends'.tr),
                    Tab(text: 'postListShuffle'.tr),
                  ],
                ),
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
                if (navState.focusedRealm.value != null)
                  MaterialBanner(
                    leading: const Icon(Icons.layers),
                    content: Text(
                      'Browsing in realm #${navState.focusedRealm.value!.alias}',
                    ),
                    actions: const [SizedBox.shrink()],
                  ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: () => _postController.reloadAllOver(),
                        child: CustomScrollView(slivers: [
                          PostWarpedListWidget(
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
                              PostWarpedListWidget(
                                controller: _postController.pagingController,
                                onUpdate: () => _postController.reloadAllOver(),
                              ),
                            ]),
                          );
                        } else {
                          return SigninRequiredOverlay(
                            onSignedIn: () => _postController.reloadAllOver(),
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

class PostCreatePopup extends StatelessWidget {
  final bool hideDraftBox;

  const PostCreatePopup({
    super.key,
    this.hideDraftBox = false,
  });

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    if (auth.isAuthorized.isFalse) {
      return const SizedBox.shrink();
    }

    final List<dynamic> actionList = [
      (
        icon: const Icon(Icons.post_add),
        label: 'postEditorModeStory'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed(
              'postEditor',
              queryParameters: {
                'mode': 0.toString(),
              },
            ),
          );
        },
      ),
      (
        icon: const Icon(Icons.description),
        label: 'postEditorModeArticle'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed(
              'postEditor',
              queryParameters: {
                'mode': 1.toString(),
              },
            ),
          );
        },
      ),
      (
        icon: const Icon(Icons.drafts),
        label: 'draftBoxOpen'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed('draftBox'),
          );
        },
      ),
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'postNew'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              children: actionList
                  .map((x) => Card(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: InkWell(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          onTap: x.onTap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              x.icon,
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  x.label,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ).paddingAll(18),
                        ),
                      ))
                  .toList(),
            ).paddingSymmetric(horizontal: 20),
          ),
        ],
      ),
    );
  }
}
