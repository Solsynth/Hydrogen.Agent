import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';

import '../providers/content/posts.dart';

class PostListController {
  /// The polling source modifier.
  /// - `0`: default recommendations
  /// - `1`: shuffle mode
  RxInt mode = 0.obs;

  /// The paging controller for infinite loading.
  /// Only available when mode is `0`.
  PagingController<int, Post> pagingController =
  PagingController(firstPageKey: 0);

  PostListController() {
    _initPagingController();
  }

  /// Initialize a compatibility layer to paging controller
  void _initPagingController() {
    pagingController.addPageRequestListener(_onPagingControllerRequest);
  }

  Future<void> _onPagingControllerRequest(int pageKey) async {
    try {
      final result = await loadMore();

      if (result != null && hasMore.value) {
        pagingController.appendPage(result, nextPageKey.value);
      } else if (result != null) {
        pagingController.appendLastPage(result);
      }
    } catch (e) {
      pagingController.error = e;
    }
  }

  void _resetPagingController() {
    pagingController.removePageRequestListener(_onPagingControllerRequest);
    pagingController.nextPageKey = nextPageKey.value;
    pagingController.itemList?.clear();
  }

  RxBool isBusy = false.obs;

  RxList<Post> postList = RxList.empty(growable: true);
  RxInt nextPageKey = 0.obs;
  RxBool hasMore = true.obs;

  Future<void> reloadAllOver() async {
    nextPageKey.value = 0;
    hasMore.value = true;
    _resetPagingController();
    final result = await loadMore();
    if (result != null && hasMore.value) {
      pagingController.appendPage(result, nextPageKey.value);
    } else if (result != null) {
      pagingController.appendLastPage(result);
    }
    _initPagingController();
  }

  Future<List<Post>?> loadMore() async {
    final result = await _loadPosts(nextPageKey.value);

    if (result != null && result.length >= 10) {
      nextPageKey.value = nextPageKey.value + result.length;
      hasMore.value = true;
    } else if (result != null) {
      nextPageKey.value = nextPageKey.value + result.length;
      hasMore.value = false;
    }

    return result;
  }

  Future<List<Post>?> _loadPosts(int pageKey) async {
    isBusy.value = true;

    final PostProvider provider = Get.find();

    Response resp;
    try {
      resp = await provider.listRecommendations(
        pageKey,
        channel: mode.value == 0 ? null : 'shuffle',
      );
    } catch (e) {
      rethrow;
    } finally {
      isBusy.value = false;
    }

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final out = result.data?.map((e) => Post.fromJson(e)).toList();

    if (out != null) postList.addAll(out.cast<Post>());

    return out;
  }

  void dispose() {
    pagingController.dispose();
  }
}
