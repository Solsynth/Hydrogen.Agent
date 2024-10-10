import 'dart:math';

import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/last_read.dart';

class PostListController extends GetxController {
  String? author;
  String? realm;

  /// The polling source modifier.
  /// - `0`: default recommendations
  /// - `1`: friend mode
  /// - `2`: shuffle mode
  RxInt mode = 0.obs;

  /// The paging controller for infinite loading.
  /// Only available when mode is `0`, `1` or `2`.
  PagingController<int, Post> pagingController =
      PagingController(firstPageKey: 0);

  PostListController({this.author}) {
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
  RxBool isPreparing = false.obs;

  RxInt focusCursor = 0.obs;

  Post get focusPost => postList[focusCursor.value];

  RxInt postTotal = 0.obs;
  RxList<Post> postList = RxList.empty(growable: true);

  RxInt nextPageKey = 0.obs;
  RxBool hasMore = true.obs;

  Future<void> reloadAllOver() async {
    isPreparing.value = true;

    focusCursor.value = 0;
    nextPageKey.value = 0;
    postList.clear();
    hasMore.value = true;

    _resetPagingController();
    final result = await loadMore();
    if (result != null && hasMore.value) {
      pagingController.appendPage(result, nextPageKey.value);
    } else if (result != null) {
      pagingController.appendLastPage(result);
    }
    _initPagingController();

    isPreparing.value = false;
  }

  Future<List<Post>?> loadMore() async {
    final result = await _loadPosts(nextPageKey.value);

    if (result != null && result.length >= 10) {
      postList.addAll(result);
      nextPageKey.value += result.length;
      hasMore.value = true;
    } else if (result != null) {
      postList.addAll(result);
      nextPageKey.value += result.length;
      hasMore.value = false;
    }

    final idx = <dynamic>{};
    postList.retainWhere((x) => idx.add(x.id));

    if (postList.isNotEmpty) {
      var lastId = postList.map((x) => x.id).reduce(max);
      Get.find<LastReadProvider>().feedLastReadAt = lastId;
    }

    return result;
  }

  Future<List<Post>?> _loadPosts(int pageKey) async {
    isBusy.value = true;

    final PostProvider posts = Get.find();

    Response resp;
    try {
      if (author != null) {
        resp = await posts.listPost(
          pageKey,
          author: author,
        );
      } else {
        switch (mode.value) {
          case 2:
            resp = await posts.listRecommendations(
              pageKey,
              channel: 'shuffle',
              realm: realm,
            );
            break;
          case 1:
            resp = await posts.listRecommendations(
              pageKey,
              channel: 'friends',
              realm: realm,
            );
            break;
          default:
            resp = await posts.listRecommendations(
              pageKey,
              realm: realm,
            );
            break;
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      isBusy.value = false;
    }

    final result = PaginationResult.fromJson(resp.body);
    final out = result.data?.map((e) => Post.fromJson(e)).toList();

    final AttachmentProvider attach = Get.find();

    if (out != null) {
      final attachmentIds = out
          .mapMany((x) => x.body['attachments'] ?? [])
          .cast<String>()
          .toSet()
          .toList();
      final attachmentOut = await attach.listMetadata(attachmentIds);

      for (var idx = 0; idx < out.length; idx++) {
        final rids = List<String>.from(out[idx].body['attachments'] ?? []);
        out[idx].preload = PostPreload(
          attachments: attachmentOut
              .where((x) => x != null && rids.contains(x.rid))
              .cast<Attachment>()
              .toList(),
        );
      }
    }

    postTotal.value = result.count;

    return out;
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }
}
