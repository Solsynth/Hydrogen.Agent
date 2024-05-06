import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RealmEditorScreen extends StatefulWidget {
  final Realm? editing;
  final String? realm;

  const RealmEditorScreen({super.key, this.editing, this.realm});

  @override
  State<RealmEditorScreen> createState() => _RealmEditorScreenState();
}

class _RealmEditorScreenState extends State<RealmEditorScreen> {
  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isPublic = false;
  bool _isCommunity = false;

  bool _isSubmitting = false;

  Future<void> applyChannel(BuildContext context) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    final uri = widget.editing == null
        ? getRequestUri('passport', '/api/realms')
        : getRequestUri('passport', '/api/realms/${widget.editing!.id}');

    final req = Request(widget.editing == null ? 'POST' : 'PUT', uri);
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(<String, dynamic>{
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'is_public': _isPublic,
      'is_community': _isCommunity,
      'realm': widget.realm,
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
    _aliasController.text = const Uuid().v4().replaceAll('-', '').substring(0, 16);
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
      _isPublic = widget.editing!.isPublic;
      _isCommunity = widget.editing!.isCommunity;
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
      content: Text(AppLocalizations.of(context)!.realmEditNotify),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => cancelEditing(),
        ),
      ],
    );

    return IndentScaffold(
      hideDrawer: true,
      title: AppLocalizations.of(context)!.realmEstablish,
      appBarActions: <Widget>[
        TextButton(
          onPressed: !_isSubmitting ? () => applyChannel(context) : null,
          child: Text(AppLocalizations.of(context)!.apply.toUpperCase()),
        ),
      ],
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      child: Column(
        children: [
          _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
          widget.editing != null ? editingBanner : Container(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.realmUsage),
            subtitle: Text(AppLocalizations.of(context)!.realmUsageCaption),
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.supervised_user_circle, color: Colors.white),
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
                      hintText: AppLocalizations.of(context)!.realmAliasLabel,
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
                hintText: AppLocalizations.of(context)!.realmNameLabel,
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
                  hintText: AppLocalizations.of(context)!.realmDescriptionLabel,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
          const Divider(thickness: 0.3),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.realmPublicLabel),
            value: _isPublic,
            onChanged: (newValue) {
              setState(() => _isPublic = newValue ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: Text(AppLocalizations.of(context)!.realmCommunityLabel),
            value: _isCommunity,
            onChanged: (newValue) {
              setState(() => _isCommunity = newValue ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          )
        ],
      ),
    );
  }
}
