import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/message.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:timeago/timeago.dart' show format;
import 'package:url_launcher/url_launcher_string.dart';

class ChatMessage extends StatelessWidget {
  final Message item;
  final bool isContentPreviewing;
  final bool isReply;
  final bool isMerged;
  final bool isHasMerged;

  const ChatMessage({
    super.key,
    required this.item,
    this.isContentPreviewing = false,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isReply = false,
  });

  Future<String?> decodeContent(Map<String, dynamic> content) async {
    String? text;
    if (item.type == 'm.text') {
      switch (content['algorithm']) {
        case 'plain':
          text = content['value'];
        default:
          throw Exception('Unsupported algorithm');
      }
    }

    return text;
  }

  Widget buildContent() {
    final hasAttachment = item.attachments?.isNotEmpty ?? false;

    return FutureBuilder(
      future: decodeContent(item.content),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Opacity(
            opacity: 0.8,
            child: Row(
              children: [
                const Icon(Icons.more_horiz),
                const SizedBox(width: 4),
                Text('messageDecoding'.tr)
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).fade(begin: 0, end: 1);
        } else if (snapshot.hasError) {
          return Opacity(
            opacity: 0.9,
            child: Row(
              children: [
                const Icon(Icons.close),
                const SizedBox(width: 4),
                Text(
                  'messageDecodeFailed'
                      .trParams({'message': snapshot.error.toString()}),
                )
              ],
            ),
          );
        }

        return Markdown(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          data: snapshot.data ?? '',
          padding: const EdgeInsets.all(0),
          onTapLink: (text, href, title) async {
            if (href == null) return;
            await launchUrlString(
              href,
              mode: LaunchMode.externalApplication,
            );
          },
        ).paddingOnly(
          left: 12,
          right: 12,
          top: 2,
          bottom: hasAttachment ? 4 : 0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (isContentPreviewing) {
      widget = buildContent();
    } else if (isMerged) {
      widget = buildContent().paddingOnly(left: 52);
    } else if (isReply) {
      widget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scaleX: -1,
            child: const FaIcon(FontAwesomeIcons.reply, size: 14),
          ),
          const SizedBox(width: 12),
          AccountAvatar(content: item.sender.account.avatar, radius: 8),
          const SizedBox(width: 4),
          Text(
            item.sender.account.nick,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: buildContent()),
        ],
      );
    } else {
      widget = Column(
        key: Key('m${item.uuid}'),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountAvatar(content: item.sender.account.avatar),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.sender.account.nick,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(format(item.createdAt, locale: 'en_short'))
                      ],
                    ).paddingSymmetric(horizontal: 12),
                    buildContent(),
                  ],
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 12),
          if (item.attachments?.isNotEmpty ?? false)
            AttachmentList(
              parentId: item.uuid,
              attachmentsId: item.attachments ?? List.empty(),
            ).paddingSymmetric(vertical: 4),
        ],
      );
    }

    if (item.isSending) {
      return Opacity(opacity: 0.65, child: widget);
    } else {
      return widget;
    }
  }
}
