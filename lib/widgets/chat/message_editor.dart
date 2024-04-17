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

  const ChatMessageEditor({super.key, required this.channel, this.editing});

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(12),
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
    );
  }
}
