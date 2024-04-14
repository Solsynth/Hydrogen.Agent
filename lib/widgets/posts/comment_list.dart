import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:http/http.dart' as http;
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/comment_editor.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/posts/item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CommentList extends StatefulWidget {
  final Post related;
  final String dataset;
  final PagingController<int, Post> paging;

  const CommentList(
      {super.key,
      required this.related,
      required this.dataset,
      required this.paging});

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  final _client = http.Client();

  Future<void> fetchComments(int pageKey) async {
    final offset = pageKey;
    const take = 5;

    final alias = widget.related.alias;

    final uri = getRequestUri('interactive',
        '/api/p/${widget.dataset}/$alias/comments?take=$take&offset=$offset');

    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final result =
          PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final items =
          result.data?.map((x) => Post.fromJson(x)).toList() ?? List.empty();
      final isLastPage = (result.count - pageKey) < take;
      if (isLastPage || result.data == null) {
        widget.paging.appendLastPage(items);
      } else {
        final nextPageKey = pageKey + items.length;
        widget.paging.appendPage(items, nextPageKey);
      }
    } else {
      widget.paging.error = utf8.decode(res.bodyBytes);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.paging.addPageRequestListener((pageKey) {
      fetchComments(pageKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Post>.separated(
      pagingController: widget.paging,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, item, index) => PostItem(item: item),
      ),
      separatorBuilder: (context, _) => const Divider(thickness: 0.3),
    );
  }
}

class CommentListHeader extends StatelessWidget {
  final Post related;
  final PagingController<int, Post> paging;

  const CommentListHeader(
      {super.key, required this.related, required this.paging});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: RichText(
              text: TextSpan(
                  text: '${AppLocalizations.of(context)!.comment} ',
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    TextSpan(
                      text: '(${related.commentCount})',
                      style: const TextStyle(
                        fontFamily: 'monospaced',
                        fontSize: 16,
                      ),
                    )
                  ]),
            ),
          ),
          FutureBuilder(
            future: auth.isAuthorized(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return TextButton(
                  onPressed: () async {
                    final did = await router.pushNamed(
                      "posts.comments.editor",
                      extra: CommentPostArguments(related: related),
                    );
                    if (did == true) paging.refresh();
                  },
                  style: TextButton.styleFrom(shape: const CircleBorder()),
                  child: const Icon(Icons.add_comment_outlined),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
