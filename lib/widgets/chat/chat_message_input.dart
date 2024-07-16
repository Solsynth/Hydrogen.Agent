import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:uuid/uuid.dart';

class ChatMessageInput extends StatefulWidget {
  final Event? edit;
  final Event? reply;
  final String? placeholder;
  final Channel channel;
  final String realm;
  final Function(Event) onSent;
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

  Event? _editTo;
  Event? _replyTo;

  void showAttachments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AttachmentPublishPopup(
        usage: 'm.attachment',
        current: _attachments,
        onUpdate: (value) => _attachments = value,
      ),
    );
  }

  Future<void> sendMessage() async {
    _focusNode.requestFocus();

    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient('messaging');

    // TODO Deal with the @ ping (query uid with username), and then add into related_user and replace the @ with internal link in body

    const uuid = Uuid();
    final payload = {
      'uuid': uuid.v4(),
      'type': _editTo == null ? 'messages.new' : 'messages.edit',
      'body': {
        'text': _textController.value.text,
        'algorithm': 'plain',
        'attachments': List.from(_attachments),
        'related_users': [
          if (_replyTo != null) _replyTo!.sender.accountId,
        ],
        if (_replyTo != null) 'quote_event': _replyTo!.id,
        if (_editTo != null) 'related_event': _editTo!.id,
      }
    };

    // The local mock data
    final sender = Sender(
      id: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      account: Account.fromJson(prof.body),
      channelId: widget.channel.id,
      accountId: prof.body['id'],
      notify: 0,
    );
    final message = Event(
      id: 0,
      uuid: payload['uuid'] as String,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      body: payload['body'] as Map<String, dynamic>,
      type: payload['type'] as String,
      sender: sender,
      channelId: widget.channel.id,
      senderId: sender.id,
    );

    if (_editTo == null) {
      message.isPending = true;
      widget.onSent(message);
    }

    resetInput();

    Response resp;
    if (_editTo != null) {
      resp = await client.put(
        '/channels/${widget.realm}/${widget.channel.alias}/messages/${_editTo!.id}',
        payload,
      );
    } else {
      resp = await client.post(
        '/channels/${widget.realm}/${widget.channel.alias}/messages',
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
    if (widget.edit != null && widget.edit!.type.startsWith('messages')) {
      final body = EventMessageBody.fromJson(widget.edit!.body);
      _editTo = widget.edit!;
      _textController.text = body.text;
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
            content: ChatEvent(
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
            content: ChatEvent(
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
