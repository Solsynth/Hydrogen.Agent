import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
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
        provider: 'interactive',
        current: _attachments,
        onUpdate: (value) => _attachments = value,
      ),
    );
  }

  Future<void> applyPost(BuildContext context) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    final uri = widget.editing == null
        ? getRequestUri('interactive', '/api/p/moments')
        : getRequestUri('interactive', '/api/p/moments/${widget.editing!.id}');

    final req = Request(widget.editing == null ? 'POST' : 'PUT', uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'alias': _alias,
      'content': _textController.value.text,
      'attachments': _attachments,
    });

    var res = await Response.fromStream(await auth.client!.send(req));
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    } else {
      if (SolianRouter.router.canPop()) {
        SolianRouter.router.pop(true);
      }
    }
    setState(() => _isSubmitting = false);
  }

  void cancelEditing() {
    if (SolianRouter.router.canPop()) {
      SolianRouter.router.pop(false);
    }
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

    final editingBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.edit_note),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text(AppLocalizations.of(context)!.postEditNotify),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => cancelEditing(),
        ),
      ],
    );

    return IndentScaffold(
      hideDrawer: true,
      title: AppLocalizations.of(context)!.newMoment,
      appBarActions: <Widget>[
        TextButton(
          onPressed: !_isSubmitting ? () => applyPost(context) : null,
          child: Text(AppLocalizations.of(context)!.postVerb.toUpperCase()),
        ),
      ],
      child: Column(
        children: [
          _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
          FutureBuilder(
            future: auth.getProfiles(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var userinfo = snapshot.data;
                return ListTile(
                  title: Text(userinfo['nick']),
                  subtitle: Text(
                    AppLocalizations.of(context)!.postIdentityNotify,
                  ),
                  leading: AccountAvatar(
                    source: userinfo['picture'],
                    direct: true,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                maxLines: null,
                autofocus: true,
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                controller: _textController,
                decoration: InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context)!.postContentPlaceholder,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
          widget.editing != null ? editingBanner : Container(),
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(width: 0.3, color: Theme.of(context).dividerColor),
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
    );
  }
}
