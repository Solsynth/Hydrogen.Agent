import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/chat/chat_message.dart';
import 'package:uuid/uuid.dart';

class ChatMessageInput extends StatefulWidget {
  final Message? edit;
  final Message? reply;
  final String? placeholder;
  final Channel channel;
  final String realm;
  final Function(Message) onSent;
  final Function()? onReset;

  const ChatMessageInput({
    super.key,
    this.edit,
    this.reply,
    this.placeholder,
    required this.channel,
    required this.realm,
    required this.onSent,
    this.onReset,
  });

  @override
  State<ChatMessageInput> createState() => _ChatMessageInputState();
}

class _ChatMessageInputState extends State<ChatMessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<int> _attachments = List.empty(growable: true);

  Message? _editTo;
  Message? _replyTo;

  void showAttachments() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPublishingPopup(
        usage: 'm.attachment',
        current: _attachments,
        onUpdate: (value) => _attachments = value,
      ),
    );
  }

  Map<String, dynamic> encodeMessage(String content) {
    return {
      'value': content.trim(),
      'keypair_id': null,
      'algorithm': 'plain',
    };
  }

  Future<void> sendMessage() async {
    _focusNode.requestFocus();

    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient('messaging');

    final payload = {
      'uuid': const Uuid().v4(),
      'type': 'm.text',
      'content': encodeMessage(_textController.value.text),
      'attachments': List.from(_attachments),
      'reply_to': _replyTo?.id,
    };

    // The mock data
    final sender = Sender(
      id: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      account: Account.fromJson(prof.body),
      channelId: widget.channel.id,
      accountId: prof.body['id'],
      notify: 0,
    );
    final message = Message(
      id: 0,
      uuid: payload['uuid'] as String,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: payload['content'] as Map<String, dynamic>,
      type: payload['type'] as String,
      attachments: _attachments,
      sender: sender,
      replyId: _replyTo?.id,
      replyTo: _replyTo,
      channelId: widget.channel.id,
      senderId: sender.id,
    );

    if (_editTo == null) {
      message.isSending = true;
      widget.onSent(message);
    }

    resetInput();

    Response resp;
    if (_editTo != null) {
      resp = await client.put(
        '/api/channels/${widget.realm}/${widget.channel.alias}/messages/${_editTo!.id}',
        payload,
      );
    } else {
      resp = await client.post(
        '/api/channels/${widget.realm}/${widget.channel.alias}/messages',
        payload,
      );
    }

    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    }
  }

  void resetInput() {
    if (widget.onReset != null) widget.onReset!();
    _editTo = null;
    _replyTo = null;
    _textController.clear();
    _attachments.clear();
    setState(() {});
  }

  void syncWidget() {
    if (widget.edit != null) {
      _editTo = widget.edit!;
      _textController.text = widget.edit!.content['value'];
    }
    if (widget.reply != null) {
      _replyTo = widget.reply!;
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ChatMessageInput oldWidget) {
    syncWidget();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final notifyBannerActions = [
      TextButton(
        onPressed: resetInput,
        child: Text('cancel'.tr),
      )
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_replyTo != null)
          MaterialBanner(
            leading: const FaIcon(FontAwesomeIcons.reply, size: 18),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.only(left: 20),
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            content: ChatMessage(
              item: _replyTo!,
              isContentPreviewing: true,
            ),
            actions: notifyBannerActions,
          ),
        if (_editTo != null)
          MaterialBanner(
            leading: const Icon(Icons.edit),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.only(left: 20),
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            content: ChatMessage(
              item: _editTo!,
              isContentPreviewing: true,
            ),
            actions: notifyBannerActions,
          ),
        SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  autocorrect: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.placeholder ??
                        'messageInputPlaceholder'.trParams(
                          {'channel': '#${widget.channel.alias}'},
                        ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: Colors.teal,
                onPressed: () => showAttachments(),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => sendMessage(),
              )
            ],
          ).paddingOnly(left: 20, right: 16),
        ),
      ],
    );
  }
}
