import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/feed/feed_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listRecommendations(pageKey);
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            showModalBottomSheet(
              useRootNavigator: true,
              isScrollControlled: true,
              context: context,
              builder: (context) => const PostCreatePopup(),
            );
          },
        ),
        body: RefreshIndicator(
          onRefresh: () => Future.sync(() => _pagingController.refresh()),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: AppBarTitle('home'.tr),
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
              ),
              FeedListWidget(controller: _pagingController),
            ],
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

class PostCreatePopup extends StatelessWidget {
  final bool hideDraftBox;
  final Function? onCreated;

  const PostCreatePopup({
    super.key,
    this.hideDraftBox = false,
    this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    if (auth.isAuthorized.isFalse) {
      return const SizedBox();
    }

    final List<dynamic> actionList = [
      (
        icon: const Icon(Icons.edit_square),
        label: 'postEditor'.tr,
        onTap: () {
          Navigator.pop(context);
          AppRouter.instance.pushNamed('postEditor').then((val) {
            if (val != null && onCreated != null) onCreated!();
          });
        },
      ),
      (
        icon: const Icon(Icons.drafts),
        label: 'draftBoxOpen'.tr,
        onTap: () {
          Navigator.pop(context);
          AppRouter.instance.pushNamed('draftBox');
        },
      ),
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
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
                              const SizedBox(height: 8),
                              Text(x.label),
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
