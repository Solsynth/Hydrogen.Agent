import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:solian/widgets/posts/comment_list.dart';
import 'package:solian/widgets/posts/post.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PostScreen extends StatelessWidget {
  final String dataset;
  final String alias;

  const PostScreen({super.key, required this.alias, required this.dataset});

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: AppLocalizations.of(context)!.post,
      hideDrawer: true,
      body: PostScreenWidget(
        dataset: dataset,
        alias: alias,
      ),
    );
  }
}

class PostScreenWidget extends StatefulWidget {
  final String dataset;
  final String alias;

  const PostScreenWidget({super.key, required this.dataset, required this.alias});

  @override
  State<PostScreenWidget> createState() => _PostScreenWidgetState();
}

class _PostScreenWidgetState extends State<PostScreenWidget> {
  final _client = http.Client();

  final PagingController<int, Post> _commentPagingController = PagingController(firstPageKey: 0);

  Future<Post?> fetchPost(BuildContext context) async {
    final uri = getRequestUri('interactive', '/api/p/${widget.dataset}/${widget.alias}');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      final err = utf8.decode(res.bodyBytes);
      context.showErrorDialog(err);
      return null;
    } else {
      return Post.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchPost(context),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PostItem(
                  item: snapshot.data!,
                  brief: false,
                  ripple: false,
                ),
              ),
              SliverToBoxAdapter(
                child: CommentListHeader(
                  related: snapshot.data!,
                  paging: _commentPagingController,
                ),
              ),
              CommentList(
                related: snapshot.data!,
                dataset: widget.dataset,
                paging: _commentPagingController,
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _commentPagingController.dispose();
    super.dispose();
  }
}
