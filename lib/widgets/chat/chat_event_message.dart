import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:solian/models/event.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChatEventMessage extends StatelessWidget {
  final Event item;
  final bool isContentPreviewing;
  final bool isQuote;
  final bool isMerged;
  final bool isHasMerged;

  const ChatEventMessage({
    super.key,
    required this.item,
    this.isContentPreviewing = false,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isQuote = false,
  });

  Widget buildContent() {
    final body = EventMessageBody.fromJson(item.body);
    final hasAttachment = body.attachments?.isNotEmpty ?? false;

    return Markdown(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      data: body.text,
      selectable: true,
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
      bottom: hasAttachment ? 4 : (isHasMerged ? 2 : 0),
    );
  }

  Widget buildBody(BuildContext context) {
    final body = EventMessageBody.fromJson(item.body);

    if (isContentPreviewing || isQuote) {
      return buildContent();
    } else if (isMerged) {
      return Column(
        children: [
          buildContent().paddingOnly(left: 52),
          if (body.attachments?.isNotEmpty ?? false)
            AttachmentList(
              key: Key('m${item.uuid}attachments'),
              parentId: item.uuid,
              attachmentsId: body.attachments ?? List.empty(),
            ).paddingSymmetric(vertical: 4),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContent(),
          if (body.attachments?.isNotEmpty ?? false)
            SizedBox(
              width: min(MediaQuery.of(context).size.width, 640),
              child: AttachmentList(
                key: Key('m${item.uuid}attachments'),
                parentId: item.uuid,
                attachmentsId: body.attachments ?? List.empty(),
                divided: true,
                viewport: 1,
              ),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildBody(context);
  }
}
