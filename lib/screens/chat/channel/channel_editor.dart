import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class ChannelEditorScreen extends StatefulWidget {
  final Channel? editing;
  final String? realm;

  const ChannelEditorScreen({super.key, this.editing, this.realm});

  @override
  State<ChannelEditorScreen> createState() => _ChannelEditorScreenState();
}

class _ChannelEditorScreenState extends State<ChannelEditorScreen> {
  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> applyChannel(BuildContext context) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    final uri = widget.editing == null
        ? getRequestUri('messaging', '/api/channels/${widget.realm ?? 'global'}')
        : getRequestUri('messaging', '/api/channels/${widget.realm ?? 'global'}/${widget.editing!.id}');

    final req = Request(widget.editing == null ? 'POST' : 'PUT', uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
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

  void randomizeAlias() {
    _aliasController.text = const Uuid().v4().replaceAll('-', '');
  }

  void cancelEditing() {
    if (SolianRouter.router.canPop()) {
      SolianRouter.router.pop(false);
    }
  }

  @override
  void initState() {
    if (widget.editing != null) {
      _aliasController.text = widget.editing!.alias;
      _nameController.text = widget.editing!.name;
      _descriptionController.text = widget.editing!.description;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final editingBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.edit_note),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text(AppLocalizations.of(context)!.chatChannelEditNotify),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => cancelEditing(),
        ),
      ],
    );

    return IndentScaffold(
      hideDrawer: true,
      showSafeArea: true,
      title: AppLocalizations.of(context)!.chatChannelOrganize,
      appBarActions: <Widget>[
        TextButton(
          onPressed: !_isSubmitting ? () => applyChannel(context) : null,
          child: Text(AppLocalizations.of(context)!.apply.toUpperCase()),
        ),
      ],
      body: Column(
        children: [
          _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
          widget.editing != null ? editingBanner : Container(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.chatChannelUsage),
            subtitle: Text(AppLocalizations.of(context)!.chatChannelUsageCaption),
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.tag, color: Colors.white),
            ),
          ),
          const Divider(thickness: 0.3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    controller: _aliasController,
                    decoration: InputDecoration.collapsed(
                      hintText: AppLocalizations.of(context)!.chatChannelAliasLabel,
                    ),
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    shape: const CircleBorder(),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  ),
                  onPressed: () => randomizeAlias(),
                  child: const Icon(Icons.refresh),
                )
              ],
            ),
          ),
          const Divider(thickness: 0.3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              autocorrect: true,
              controller: _nameController,
              decoration: InputDecoration.collapsed(
                hintText: AppLocalizations.of(context)!.chatChannelNameLabel,
              ),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          const Divider(thickness: 0.3),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                minLines: 5,
                maxLines: null,
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                controller: _descriptionController,
                decoration: InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context)!.chatChannelDescriptionLabel,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
