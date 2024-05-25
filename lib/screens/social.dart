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
import 'package:solian/widgets/posts/post_list.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
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
    final AuthProvider auth = Get.find();

    return Scaffold(
      floatingActionButton: FutureBuilder(
          future: auth.isAuthorized,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  final value =
                      await AppRouter.instance.pushNamed('postPublishing');
                  if (value != null) {
                    _pagingController.refresh();
                  }
                },
              );
            }
            return Container();
          }),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    title: Text('social'.tr),
                    centerTitle: false,
                    titleSpacing:
                        SolianTheme.isLargeScreen(context) ? null : 24,
                    forceElevated: innerBoxIsScrolled,
                    actions: [
                      const NotificationButton(),
                      SizedBox(
                        width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: RefreshIndicator(
                onRefresh: () => Future.sync(() => _pagingController.refresh()),
                child: PostListWidget(controller: _pagingController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
