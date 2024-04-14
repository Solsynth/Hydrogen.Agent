import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:solian/widgets/posts/attachment_editor.dart';

class NewMomentScreen extends StatefulWidget {
  const NewMomentScreen({super.key});

  @override
  State<NewMomentScreen> createState() => _NewMomentScreenState();
}

class _NewMomentScreenState extends State<NewMomentScreen> {
  final _textController = TextEditingController();

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

  Future<void> createPost(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    setState(() => _isSubmitting = true);
    var res = await auth.client!.post(
      getRequestUri('interactive', '/api/p/moments'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'content': _textController.value.text,
        'attachments': _attachments,
      }),
    );
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
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return IndentWrapper(
      hideDrawer: true,
      title: AppLocalizations.of(context)!.newMoment,
      appBarActions: <Widget>[
        TextButton(
          onPressed: !_isSubmitting ? () => createPost(context) : null,
          child: Text(AppLocalizations.of(context)!.postVerb),
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
