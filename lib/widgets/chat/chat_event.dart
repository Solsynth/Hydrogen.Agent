import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/event.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/chat/chat_event_action_log.dart';
import 'package:solian/widgets/chat/chat_event_message.dart';
import 'package:solian/widgets/link_expansion.dart';
import 'package:timeago/timeago.dart' show format;

class ChatEvent extends StatelessWidget {
  final Event item;
  final bool isContentPreviewing;
  final bool isQuote;
  final bool isMerged;
  final bool isHasMerged;

  final ChatEventController? chatController;

  const ChatEvent({
    super.key,
    required this.item,
    this.isContentPreviewing = false,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isQuote = false,
    this.chatController,
  });

  String _formatDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget _buildLinkExpansion() {
    if (item.body['text'] == null) return const SizedBox.shrink();
    return LinkExpansion(content: item.body['text']);
  }

  Widget _buildAttachment(BuildContext context, {bool isMinimal = false}) {
    final attachments = item.body['attachments'] != null
        ? List<String>.from(item.body['attachments']?.whereType<String>())
        : List<String>.empty();

    if (attachments.isEmpty) return const SizedBox.shrink();

    if (isMinimal) {
      final unFocusColor =
          Theme.of(context).colorScheme.onSurface.withOpacity(0.75);
      return Row(
        children: [
          Icon(
            Icons.file_copy,
            size: 15,
            color: unFocusColor,
          ).paddingOnly(right: 5),
          Text(
            'attachmentHint'.trParams(
              {'count': attachments.length.toString()},
            ),
            style: TextStyle(color: unFocusColor),
          )
        ],
      );
    }

    return Container(
      key: Key('m${item.uuid}attachments-box'),
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(top: isMerged ? 0 : 4, bottom: 4),
      child: AttachmentList(
        key: Key('m${item.uuid}attachments'),
        parentId: item.uuid,
        attachmentIds: attachments,
        isColumn: true,
      ),
    );
  }

  Widget _buildQuote() {
    return FutureBuilder(
      future: chatController!.getEvent(
        item.body['quote_event'],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ChatEvent(
            item: snapshot.data!.data!,
            isMerged: false,
            isQuote: true,
          ),
        ).paddingOnly(left: isMerged ? 52 : 0);
      },
    );
  }

  Widget _buildContent() {
    switch (item.type) {
      case 'messages.new':
        return ChatEventMessage(
          item: item,
          isContentPreviewing: isContentPreviewing,
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'messages.edit':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.edit_note, size: 16),
          text: 'messageEditDesc'.trParams({
            'id': '#${item.body['related_event']}',
          }),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'messages.delete':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.cancel_schedule_send, size: 16),
          text: 'messageDeleteDesc'.trParams({
            'id': '#${item.body['related_event']}',
          }),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'calls.start':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.call_made, size: 16),
          text: 'messageCallStartDesc'
              .trParams({'user': '@${item.sender.account.name}'}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'calls.end':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.call_received, size: 16),
          text: 'messageCallEndDesc'.trParams({
            'duration': _formatDuration(
              Duration(seconds: item.body['last']),
            ),
          }),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'system.changes':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.manage_history, size: 16),
          text: item.body['text'],
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      default:
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.error, size: 16),
          text: 'messageTypeUnsupported'.trParams({'type': item.type}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
    }
  }

  Widget _buildBody(BuildContext context) {
    if (isContentPreviewing || (isMerged && !isQuote)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.body['quote_event'] != null && chatController != null)
            _buildQuote(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildContent()),
              if (item.isPending)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ).paddingOnly(right: 12),
          if (!isContentPreviewing)
            _buildLinkExpansion().paddingOnly(left: 52, right: 8),
          _buildAttachment(context, isMinimal: isContentPreviewing).paddingOnly(
            left: isContentPreviewing ? 12 : 56,
            right: 8,
          ),
        ],
      );
    } else if (isQuote) {
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Opacity(
              opacity: 0.75,
              child: FaIcon(FontAwesomeIcons.quoteLeft, size: 14),
            ).paddingOnly(bottom: 2.75),
            const Gap(4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AttachedCircleAvatar(
                        content: item.sender.account.avatar,
                        radius: 9,
                      ),
                      const Gap(5),
                      Text(
                        item.sender.account.nick,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Gap(4),
                      Text(format(item.createdAt, locale: 'en_short')),
                    ],
                  ),
                  _buildContent().paddingOnly(left: 0.5),
                  _buildAttachment(context, isMinimal: true),
                ],
              ),
            ),
          ],
        ).paddingOnly(left: 12, right: 12, top: 8, bottom: 4),
      ).paddingOnly(left: isMerged ? 52 : 0, right: 4);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: Key('m${item.uuid}'),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child:
                    AttachedCircleAvatar(content: item.sender.account.avatar),
                onTap: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    context: context,
                    builder: (context) => AccountProfilePopup(
                      name: item.sender.account.name,
                    ),
                  );
                },
              ),
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
                        const Gap(4),
                        Text(format(item.createdAt, locale: 'en_short'))
                      ],
                    ).paddingSymmetric(horizontal: 12),
                    if (item.body['quote_event'] != null &&
                        chatController != null)
                      _buildQuote(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildContent()),
                        if (item.isPending)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 12),
          _buildLinkExpansion().paddingOnly(left: 52, right: 8),
          _buildAttachment(
            context,
            isMinimal: ['messages.edit'].contains(item.type),
          ).paddingOnly(left: 56, right: 8),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}
