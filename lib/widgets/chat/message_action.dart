import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/chat/message_deletion.dart';

class ChatMessageAction extends StatelessWidget {
  final String channel;
  final Message item;
  final Function? onEdit;
  final Function? onReply;

  const ChatMessageAction({
    super.key,
    required this.channel,
    required this.item,
    this.onEdit,
    this.onReply,
  });

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
                  'Message ID #${item.id.toString().padLeft(8, '0')}',
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
                      onTap: () {
                        if (onEdit != null) onEdit!();
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: Text(AppLocalizations.of(context)!.delete),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ChatMessageDeletionDialog(
                            item: item,
                            channel: channel,
                          ),
                        ).then((did) {
                          if (did == true && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        });
                      },
                    )
                  ];

                  return ListView(
                    children: [
                      ...(snapshot.data['id'] == item.sender.account.externalId
                          ? authorizedItems
                          : List.empty()),
                      ListTile(
                        leading: const Icon(Icons.reply),
                        title: Text(AppLocalizations.of(context)!.reply),
                        onTap: () {
                          if (onReply != null) onReply!();
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
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
