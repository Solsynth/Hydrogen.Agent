import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';

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

  bool _isSubmitting = false;

  Future<void> sendMessage(BuildContext context) async {
    if (_isSubmitting) return;

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri = widget.editing == null
        ? getRequestUri('messaging', '/api/channels/${widget.channel}/messages')
        : getRequestUri('messaging', '/api/channels/${widget.channel}/messages/${widget.editing!.id}');

    final req = Request(widget.editing == null ? "POST" : "PUT", uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'content': _textController.value.text,
      'reply_to': widget.replying?.id,
    });

    setState(() => _isSubmitting = true);
    var res = await Response.fromStream(await auth.client!.send(req));
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    } else {
      reset();
    }
    setState(() => _isSubmitting = false);
  }

  void reset() {
    _textController.clear();

    if (widget.onReset != null) widget.onReset!();
  }

  void syncWidget() {
    if (widget.editing != null) {
      setState(() {
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
    final editingBanner = MaterialBanner(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      leading: const Icon(Icons.edit_note),
      backgroundColor: const Color(0xFFE0E0E0),
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
      backgroundColor: const Color(0xFFE0E0E0),
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
          padding: const EdgeInsets.only(top: 4, left: 16, right: 8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.3, color: Color(0xffdedede)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  autofocus: true,
                  autocorrect: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration.collapsed(
                    hintText: AppLocalizations.of(context)!.chatMessagePlaceholder,
                  ),
                  onSubmitted: (_) => sendMessage(context),
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
