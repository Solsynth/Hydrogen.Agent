import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/chat/message_deletion.dart';

class ChatMessageAction extends StatelessWidget {
  final String channel;
  final String realm;
  final Message item;
  final Function? onEdit;
  final Function? onReply;

  const ChatMessageAction({
    super.key,
    required this.channel,
    required this.item,
    this.realm = 'global',
    this.onEdit,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return SizedBox(
      height: 400,
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
                            realm: realm,
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
                      ...(snapshot.data['id'] == item.sender.account.externalId ? authorizedItems : List.empty()),
                      ListTile(
                        leading: const Icon(Icons.reply),
                        title: Text(AppLocalizations.of(context)!.reply),
                        onTap: () {
                          if (onReply != null) onReply!();
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: Text(AppLocalizations.of(context)!.chatMessageViewSource),
                        onTap: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => ChatMessageSourceWidget(item: item),
                          );
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

class ChatMessageSourceWidget extends StatelessWidget {
  final Message item;

  const ChatMessageSourceWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      child: SizedBox(
        width: double.infinity,
        height: 640,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chatMessageViewSource,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
              child: Text(
                'Raw content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Markdown(
              selectable: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              data: '```\n${item.rawContent}\n```',
              padding: const EdgeInsets.all(0),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
              child: Text(
                'Decoded content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Markdown(
              selectable: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              data: '```\n${const JsonEncoder.withIndent('    ').convert(item.decodedContent)}\n```',
              padding: const EdgeInsets.all(0),
              styleSheet: MarkdownStyleSheet(
                code: GoogleFonts.robotoMono(
                  backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                  fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * 0.85,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
              child: Text(
                'Entire message',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Markdown(
              selectable: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              data: '```\n${const JsonEncoder.withIndent('    ').convert(item)}\n```',
              padding: const EdgeInsets.all(0),
              styleSheet: MarkdownStyleSheet(
                code: GoogleFonts.robotoMono(
                  backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                  fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * 0.85,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
