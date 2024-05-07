import 'dart:convert';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/posts/attachment_editor.dart';
import 'package:badges/badges.dart' as badge;

class ChatMessageEditor extends StatefulWidget {
  final String channel;
  final String realm;
  final Message? editing;
  final Message? replying;
  final Function? onReset;

  const ChatMessageEditor({
    super.key,
    required this.channel,
    this.realm = 'global',
    this.editing,
    this.replying,
    this.onReset,
  });

  @override
  State<ChatMessageEditor> createState() => _ChatMessageEditorState();
}

class _ChatMessageEditorState extends State<ChatMessageEditor> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  List<int> _pendingMessages = List.empty(growable: true);

  int? _prevEditingId;

  List<Attachment> _attachments = List.empty(growable: true);

  void viewAttachments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditor(
        provider: 'messaging',
        current: _attachments,
        onUpdate: (value) => setState(() => _attachments = value),
      ),
    );
  }

  Future<void> sendMessage(BuildContext context) async {
    _focusNode.requestFocus();

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri = widget.editing == null
        ? getRequestUri('messaging', '/api/channels/${widget.realm}/${widget.channel}/messages')
        : getRequestUri('messaging', '/api/channels/${widget.realm}/${widget.channel}/messages/${widget.editing!.id}');

    final req = Request(widget.editing == null ? 'POST' : 'PUT', uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'content': _textController.value.text,
      'attachments': _attachments,
      'reply_to': widget.replying?.id,
    });

    reset();

    final messageMarkId = DateTime.now().microsecondsSinceEpoch >> 10;
    final messageDebounceId = 'm-pending$messageMarkId';

    EasyDebounce.debounce(messageDebounceId, 350.ms, () {
      setState(() => _pendingMessages.add(messageMarkId));
    });

    var res = await Response.fromStream(await auth.client!.send(req));
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    EasyDebounce.cancel(messageDebounceId);
    if (_pendingMessages.isNotEmpty) {
      setState(() => _pendingMessages.remove(messageMarkId));
    }
  }

  void reset() {
    _textController.clear();
    _attachments.clear();

    if (widget.onReset != null) widget.onReset!();
  }

  void syncWidget() {
    if (widget.editing != null && _prevEditingId != widget.editing!.id) {
      setState(() {
        _prevEditingId = widget.editing!.id;
        _attachments = widget.editing!.attachments ?? List.empty(growable: true);
        _textController.text = widget.editing!.content;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    syncWidget();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final sendingBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.schedule_send),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text('${AppLocalizations.of(context)!.chatMessageSending} (${_pendingMessages.length})'),
      actions: const [SizedBox()],
    );

    final editingBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.edit_note),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text(AppLocalizations.of(context)!.chatMessageEditNotify),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => reset(),
        ),
      ],
    );

    final replyingBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.reply),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text(AppLocalizations.of(context)!.chatMessageReplyNotify),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => reset(),
        ),
      ],
    );

    return Column(
      children: [
        _pendingMessages.isNotEmpty
            ? sendingBanner
                .animate()
                .scaleY(
                  begin: 0,
                  curve: Curves.fastEaseInToSlowEaseOut,
                )
                .slideY(
                  begin: 1,
                  curve: Curves.fastEaseInToSlowEaseOut,
                )
            : Container(),
        widget.editing != null ? editingBanner : Container(),
        widget.replying != null ? replyingBanner : Container(),
        Container(
          height: 56,
          padding: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.3, color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              badge.Badge(
                showBadge: _attachments.isNotEmpty,
                badgeContent: Text(_attachments.length.toString(), style: const TextStyle(color: Colors.white)),
                position: badge.BadgePosition.custom(top: -2, end: 8),
                child: TextButton(
                  style: TextButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(4)),
                  onPressed: () => viewAttachments(context),
                  child: const Icon(Icons.attach_file),
                ),
              ),
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textController,
                  maxLines: null,
                  autocorrect: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration.collapsed(
                    hintText: AppLocalizations.of(context)!.chatMessagePlaceholder,
                  ),
                  onSubmitted: (_) => sendMessage(context),
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(4)),
                onPressed: () => sendMessage(context),
                child: const Icon(Icons.send),
              )
            ],
          ),
        ),
      ],
    );
  }
}
