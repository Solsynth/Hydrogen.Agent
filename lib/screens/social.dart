import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/post_explore.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  getPosts(int pageKey) async {
    final PostExploreProvider provider = Get.find();
    final resp = await provider.listPost(pageKey);
    if (resp.statusCode != 200) {
      _pagingController.error = resp.bodyString;
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
    Get.lazyPut(() => PostExploreProvider());
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
        child: RefreshIndicator(
          onRefresh: () => Future.sync(() => _pagingController.refresh()),
          child: PagedListView<int, Post>.separated(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Post>(
              itemBuilder: (context, item, index) {
                return GestureDetector(
                  child: PostItem(key: Key('p${item.alias}'), item: item)
                      .paddingSymmetric(
                    vertical: (item.attachments?.isEmpty ?? false) ? 8 : 0,
                  ),
                  onTap: () {},
                  onLongPress: () {
                    showModalBottomSheet(
                      useRootNavigator: true,
                      context: context,
                      builder: (context) => PostAction(item: item),
                    ).then((value) {
                      if (value == true) _pagingController.refresh();
                    });
                  },
                );
              },
            ),
            separatorBuilder: (_, __) =>
                const Divider(thickness: 0.3, height: 0.3),
          ),
        ),
      ),
    );
  }
}
