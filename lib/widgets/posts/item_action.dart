import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/posts/item_deletion.dart';

class PostItemAction extends StatelessWidget {
  final Post item;
  final Function? onUpdate;

  const PostItemAction({super.key, required this.item, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return SizedBox(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
            child: Text(
              AppLocalizations.of(context)!.action,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: auth.getProfiles(),
              builder: (context, snapshot) {
                print(snapshot);
                if (snapshot.hasData) {
                  final authorizedItems = [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(AppLocalizations.of(context)!.edit),
                      onTap: () {
                        router
                            .pushNamed('posts.moments.editor', extra: item)
                            .then((did) {
                          if (did == true && onUpdate != null) {
                            onUpdate!();
                          }
                        });
                      },
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
                            onDelete: (did) {
                              if(did == true && onUpdate != null) onUpdate!();
                            },
                          ),
                        );
                      },
                    )
                  ];

                  return ListView(
                    children: [
                      ...(snapshot.data['id'] == item.authorId
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
