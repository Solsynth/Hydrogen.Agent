import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_owned_list.dart';

class DraftBoxScreen extends StatefulWidget {
  const DraftBoxScreen({super.key});

  @override
  State<DraftBoxScreen> createState() => _DraftBoxScreenState();
}

class _DraftBoxScreenState extends State<DraftBoxScreen> {
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  _getPosts(int pageKey) async {
    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listDraft(pageKey);
    } catch (e) {
      _pagingController.error = e;
      return;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    if (result.count == 0) {
      _pagingController.appendLastPage([]);
      return;
    }

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
    _pagingController.addPageRequestListener(_getPosts);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('draftBox'.tr),
          centerTitle: false,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          actions: [
            SizedBox(
              width: SolianTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => Future.sync(() => _pagingController.refresh()),
          child: PagedListView<int, Post>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (context, item, index) {
                return PostOwnedListEntry(
                  item: item,
                  isFullContent: true,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  onTap: () async {
                    showModalBottomSheet(
                      useRootNavigator: true,
                      context: context,
                      builder: (context) => PostAction(
                        item: item,
                        noReact: true,
                      ),
                    ).then((value) {
                      if (value is Future) {
                        value.then((_) {
                          _pagingController.refresh();
                        });
                      } else if (value != null) {
                        _pagingController.refresh();
                      }
                    });
                  },
                ).paddingOnly(left: 12, right: 12, bottom: 4);
              },
            ),
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
