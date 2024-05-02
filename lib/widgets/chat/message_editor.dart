import 'dart:convert';

import 'package:flutter/material.dart';
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
  final Message? editing;
  final Message? replying;
  final Function? onReset;

  const ChatMessageEditor({super.key, required this.channel, this.editing, this.replying, this.onReset});

  @override
  State<ChatMessageEditor> createState() => _ChatMessageEditorState();
}

class _ChatMessageEditorState extends State<ChatMessageEditor> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSubmitting = false;
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
    if (_isSubmitting) return;

    _focusNode.requestFocus();

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri = widget.editing == null
        ? getRequestUri('messaging', '/api/channels/${widget.channel}/messages')
        : getRequestUri('messaging', '/api/channels/${widget.channel}/messages/${widget.editing!.id}');

    final req = Request(widget.editing == null ? 'POST' : 'PUT', uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'content': _textController.value.text,
      'attachments': _attachments,
      'reply_to': widget.replying?.id,
    });

    setState(() => _isSubmitting = true);
    var res = await Response.fromStream(await auth.client!.send(req));
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    } else {
      reset();
    }
    setState(() => _isSubmitting = false);
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
        _textController.text = widget.editing!.content;
        _attachments = widget.editing!.attachments ?? List.empty(growable: true);
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
    final editingBanner = MaterialBanner(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
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
                  onPressed: !_isSubmitting ? () => viewAttachments(context) : null,
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
                onPressed: !_isSubmitting ? () => sendMessage(context) : null,
                child: const Icon(Icons.send),
              )
            ],
          ),
        ),
      ],
    );
  }
}
