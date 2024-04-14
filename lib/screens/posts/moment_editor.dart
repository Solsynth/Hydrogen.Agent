import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:solian/widgets/posts/attachment_editor.dart';

class MomentEditorScreen extends StatefulWidget {
  final Post? editing;

  const MomentEditorScreen({super.key, this.editing});

  @override
  State<MomentEditorScreen> createState() => _MomentEditorScreenState();
}

class _MomentEditorScreenState extends State<MomentEditorScreen> {
  final _textController = TextEditingController();

  String? _alias;
  bool _isSubmitting = false;

  List<Attachment> _attachments = List.empty(growable: true);

  void viewAttachments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditor(
        current: _attachments,
        onUpdate: (value) => _attachments = value,
      ),
    );
  }

  Future<void> applyPost(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri = widget.editing == null
        ? getRequestUri('interactive', '/api/p/moments')
        : getRequestUri('interactive', '/api/p/moments/${widget.editing!.id}');

    final req = Request(widget.editing == null ? "POST" : "PUT", uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'alias': _alias,
      'content': _textController.value.text,
      'attachments': _attachments,
    });

    setState(() => _isSubmitting = true);
    var res = await Response.fromStream(await auth.client!.send(req));
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    } else {
      if (router.canPop()) {
        router.pop(true);
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  void initState() {
    if (widget.editing != null) {
      _alias = widget.editing!.alias;
      _textController.text = widget.editing!.content;
      _attachments = widget.editing!.attachments ?? List.empty(growable: true);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return IndentWrapper(
      hideDrawer: true,
      title: AppLocalizations.of(context)!.newMoment,
      appBarActions: <Widget>[
        TextButton(
          onPressed: !_isSubmitting ? () => applyPost(context) : null,
          child: Text(AppLocalizations.of(context)!.postVerb.toUpperCase()),
        ),
      ],
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _isSubmitting ? const LinearProgressIndicator() : Container(),
              FutureBuilder(
                future: auth.getProfiles(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var userinfo = snapshot.data;
                    return ListTile(
                      title: Text(userinfo["nick"]),
                      subtitle: Text(
                        AppLocalizations.of(context)!.postIdentityNotify,
                      ),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userinfo["picture"]),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              const Divider(thickness: 0.3),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    maxLines: null,
                    autofocus: true,
                    autocorrect: true,
                    keyboardType: TextInputType.multiline,
                    controller: _textController,
                    decoration: InputDecoration.collapsed(
                      hintText:
                          AppLocalizations.of(context)!.postContentPlaceholder,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 0.3, color: Color(0xffdedede)),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: const Icon(Icons.camera_alt),
                      onPressed: () => viewAttachments(context),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}