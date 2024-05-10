import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/screens/posts/comment_editor.dart';
import 'package:solian/widgets/posts/post_deletion.dart';

class PostItemAction extends StatelessWidget {
  final Post item;
  final Function? onUpdate;
  final Function? onDelete;

  const PostItemAction({
    super.key,
    required this.item,
    this.onUpdate,
    this.onDelete,
  });

  void viewEditor() async {
    bool ok = false;
    switch (item.modelType) {
      case 'article':
        ok = await SolianRouter.router.pushNamed(
          'posts.articles.editor',
          extra: item,
        ) as bool;
      case 'moment':
        ok = await SolianRouter.router.pushNamed(
          'posts.moments.editor',
          extra: item,
        ) as bool;
      case 'comment':
        ok = await SolianRouter.router.pushNamed(
          'posts.comments.editor',
          extra: CommentPostArguments(editing: item),
        ) as bool;
    }

    if (ok == true && onUpdate != null) {
      onUpdate!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return SizedBox(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.action,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '#${item.id.toString().padLeft(8, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: auth.getProfiles(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final authorizedItems = [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(AppLocalizations.of(context)!.edit),
                      onTap: () => viewEditor(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: Text(AppLocalizations.of(context)!.delete),
                      onTap: () {
                        final dataset = '${item.modelType}s';
                        showDialog(
                          context: context,
                          builder: (context) => ItemDeletionDialog(
                            item: item,
                            dataset: dataset,
                          ),
                        ).then((did) {
                          if (did == true && onDelete != null) onDelete!();
                        });
                      },
                    )
                  ];

                  return ListView(
                    children: [
                      ...(snapshot.data['id'] == item.author.externalId
                          ? authorizedItems
                          : List.empty()),
                      ListTile(
                        leading: const Icon(Icons.report),
                        title: Text(AppLocalizations.of(context)!.report),
                        onTap: () {},
                      )
                    ],
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
