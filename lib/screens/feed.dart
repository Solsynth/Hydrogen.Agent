import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/feed.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/feed/feed_list.dart';
import 'package:solian/widgets/drawer_button.dart' as drawer;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PagingController<int, FeedRecord> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final FeedProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listFeed(pageKey);
    } catch (e) {
      _pagingController.error = e;
      return;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final parsed = result.data?.map((e) => FeedRecord.fromJson(e)).toList();
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
    return Scaffold(
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: () => Future.sync(() => _pagingController.refresh()),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: AppBarTitle('feed'.tr),
                centerTitle: false,
                floating: true,
                toolbarHeight: SolianTheme.toolbarHeight(context),
                leading: const drawer.DrawerButton(),
                actions: [
                  const BackgroundStateWidget(),
                  const NotificationButton(),
                  FeedCreationButton(
                    onCreated: () {
                      _pagingController.refresh();
                    },
                  ),
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

class FeedCreationButton extends StatelessWidget {
  final bool hideDraftBox;
  final Function? onCreated;

  const FeedCreationButton({
    super.key,
    this.hideDraftBox = false,
    this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return FutureBuilder(
        future: auth.isAuthorized,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return PopupMenuButton(
              icon: const Icon(Icons.edit_square),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: ListTile(
                    title: Text('postEditor'.tr),
                    leading: const Icon(Icons.article),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    AppRouter.instance.pushNamed('postEditor').then((val) {
                      if (val != null && onCreated != null) {
                        onCreated!();
                      }
                    });
                  },
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text('articleEditor'.tr),
                    leading: const Icon(Icons.newspaper),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    AppRouter.instance.pushNamed('articleEditor').then((val) {
                      if (val != null && onCreated != null) {
                        onCreated!();
                      }
                    });
                  },
                ),
                if (!hideDraftBox)
                  PopupMenuItem(
                    child: ListTile(
                      title: Text('draftBoxOpen'.tr),
                      leading: const Icon(Icons.drafts),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onTap: () {
                      AppRouter.instance.pushNamed('draftBox');
                    },
                  ),
              ],
            );
          }
          return const SizedBox();
        });
  }
}
