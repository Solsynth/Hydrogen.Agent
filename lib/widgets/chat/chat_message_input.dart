import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
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
      'value': content,
      'keypair_id': null,
      'algorithm': 'plain',
    };
  }

  Future<void> sendMessage() async {
    _focusNode.requestFocus();

    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    if (!await auth.isAuthorized) return;

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final payload = {
      'uuid': const Uuid().v4(),
      'type': 'm.text',
      'content': encodeMessage(_textController.value.text),
      'attachments': _attachments,
      'reply_to': widget.reply?.id,
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
      sender: sender,
      replyId: widget.reply?.id,
      replyTo: widget.reply,
      channelId: widget.channel.id,
      senderId: sender.id,
    );

    if (widget.edit == null) widget.onSent(message);
    resetInput();

    Response resp;
    if (widget.edit != null) {
      resp = await client.put(
        '/api/channels/${widget.realm}/${widget.channel.alias}/messages/${widget.edit!.id}',
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
    _textController.clear();
  }

  void syncWidget() {
    if (widget.edit != null) {
      _textController.text = widget.edit!.content['value'];
    }
  }

  @override
  void didUpdateWidget(covariant ChatMessageInput oldWidget) {
    syncWidget();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(20));

    final notifyBannerActions = [
      TextButton(
        onPressed: resetInput,
        child: Text('cancel'.tr),
      )
    ];

    return Material(
      borderRadius: borderRadius,
      elevation: 2,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.edit != null)
              MaterialBanner(
                leading: const Icon(Icons.edit),
                dividerColor: Colors.transparent,
                content: ChatMessage(
                  item: widget.edit!,
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
              ).paddingOnly(left: 16, right: 4),
            ),
          ],
        ),
      ),
    );
  }
}
