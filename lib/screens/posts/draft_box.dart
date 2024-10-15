import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class DraftBoxScreen extends StatefulWidget {
  const DraftBoxScreen({super.key});

  @override
  State<DraftBoxScreen> createState() => _DraftBoxScreenState();
}

class _DraftBoxScreenState extends State<DraftBoxScreen> {
  bool _isBusy = true;
  int? _totalPosts;
  final List<Post> _posts = List.empty(growable: true);

  _getPosts() async {
    setState(() => _isBusy = true);

    final PostProvider posts = Get.find();
    final resp = await posts.listDraft(_posts.length);

    final PaginationResult result = PaginationResult.fromJson(resp.body);

    final parsed = result.data?.map((e) => Post.fromJson(e)).toList();
    _totalPosts = result.count;
    _posts.addAll(parsed ?? List.empty());

    setState(() => _isBusy = false);
  }

  Future<void> _openActions(Post item) async {
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
          _posts.clear();
          _getPosts();
        });
      } else if (value != null) {
        _posts.clear();
        _getPosts();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('draftBox'.tr),
          centerTitle: false,
          toolbarHeight: AppTheme.toolbarHeight(context),
          actions: [
            SizedBox(
              width: AppTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
        ),
        body: Column(
          children: [
            LoadingIndicator(isActive: _isBusy),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () {
                  _posts.clear();
                  return _getPosts();
                },
                child: InfiniteList(
                  itemCount: _posts.length,
                  hasReachedMax: _totalPosts == _posts.length,
                  isLoading: _isBusy,
                  onFetchData: () => _getPosts(),
                  itemBuilder: (context, index) {
                    final item = _posts[index];
                    return Card(
                      child: GestureDetector(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostItem(
                              key: Key('p${item.id}'),
                              item: item,
                              isShowEmbed: false,
                              isClickable: false,
                              isShowReply: false,
                              isReactable: false,
                              onTapMore: () => _openActions(item),
                            ).paddingSymmetric(vertical: 8),
                          ],
                        ),
                        onTap: () => _openActions(item),
                      ),
                    ).paddingOnly(left: 12, right: 12, bottom: 4);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
