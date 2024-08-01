import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/event.dart';
import 'package:solian/widgets/markdown_text_content.dart';

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

  Widget _buildContent(BuildContext context) {
    final body = EventMessageBody.fromJson(item.body);
    final hasAttachment = body.attachments?.isNotEmpty ?? false;

    if (body.text.isEmpty && hasAttachment) {
      final unFocusColor =
          Theme.of(context).colorScheme.onSurface.withOpacity(0.75);
      return Row(
        children: [
          Icon(
            Icons.attachment,
            size: 18,
            color: unFocusColor,
          ).paddingOnly(right: 6),
          Text(
            'attachmentHint'.trParams(
              {'count': body.attachments?.length.toString() ?? 0.toString()},
            ),
            style: TextStyle(color: unFocusColor),
          )
        ],
      );
    }

    return MarkdownTextContent(content: body.text);
  }

  Widget _buildBody(BuildContext context) {
    if (isMerged) {
      return _buildContent(context).paddingOnly(left: 52);
    } else {
      return _buildContent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = EventMessageBody.fromJson(item.body);
    final hasAttachment = body.attachments?.isNotEmpty ?? false;

    return _buildBody(context).paddingOnly(
      left: isQuote ? 0 : 12,
      right: isQuote ? 0 : 12,
      top: body.quoteEvent == null ? 2 : 0,
      bottom: hasAttachment && !isContentPreviewing ? 4 : (isHasMerged ? 2 : 0),
    );
  }
}
