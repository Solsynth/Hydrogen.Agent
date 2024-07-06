import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/post.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/posts/post_list.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listPost(pageKey);
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
                titleSpacing: SolianTheme.titleSpacing(context),
                toolbarHeight: SolianTheme.toolbarHeight(context),
                actions: [
                  const BackgroundStateWidget(),
                  const NotificationButton(),
                  const FeedCreationButton(),
                  SizedBox(
                    width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                  ),
                ],
              ),
              PostListWidget(controller: _pagingController),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedCreationButton extends StatelessWidget {
  const FeedCreationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return FutureBuilder(
        future: auth.isAuthorized,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                AppRouter.instance.pushNamed('postPublishing');
              },
            );
          }
          return const SizedBox();
        });
  }
}
