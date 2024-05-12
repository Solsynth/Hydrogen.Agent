import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/keypair.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatMessageContent extends StatefulWidget {
  final Message item;

  const ChatMessageContent({super.key, required this.item});

  @override
  State<ChatMessageContent> createState() => _ChatMessageContentState();
}

class _ChatMessageContentState extends State<ChatMessageContent> {
  @override
  Widget build(BuildContext context) {
    final feColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);

    final waitingKeyHint = Row(
      children: [
        Icon(Icons.key, color: feColor, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.chatMessageUnableDecryptWaiting,
            style: TextStyle(color: feColor),
          ),
        ),
      ],
    );
    final missingKeyHint = Row(
      children: [
        Icon(Icons.key_off_outlined, color: feColor, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.chatMessageUnableDecryptMissing,
            style: TextStyle(color: feColor),
          ),
        ),
      ],
    );

    if (widget.item.type == 'm.text') {
      String? content;
      switch (widget.item.decodedContent['algorithm']) {
        case 'plain':
          content = widget.item.decodedContent['value'];
        case 'aes':
          final keypair = context.watch<KeypairProvider>();
          if (keypair.keys[widget.item.decodedContent['keypair_id']] == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (keypair.requestKey(
                widget.item.decodedContent['keypair_id'],
                widget.item.decodedContent['algorithm'],
                widget.item.sender.account.externalId!,
              )) {
              }
            });
          } else {
            content = keypair.decodeViaAESKey(
              widget.item.decodedContent['keypair_id'],
              widget.item.decodedContent['value'],
            )!;
            break;
          }

          if (keypair.requestingKeys.contains(widget.item.decodedContent['keypair_id'])) {
            return waitingKeyHint.animate().swap(builder: (context, _) {
              return missingKeyHint;
            }, delay: 3000.ms);
          }
      }

      if (content == null) {
        return Row(
          children: [
            Icon(Icons.key_off, color: feColor, size: 16),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.chatMessageUnableDecryptUnsupported,
              style: TextStyle(color: feColor),
            ),
          ],
        );
      }

      return Markdown(
        data: content,
        shrinkWrap: true,
        selectable: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        onTapLink: (text, href, title) async {
          if (href == null) return;
          await launchUrlString(
            href,
            mode: LaunchMode.externalApplication,
          );
        },
      );
    }

    return Container();
  }
}
