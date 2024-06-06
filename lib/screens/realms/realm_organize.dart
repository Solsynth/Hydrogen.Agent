import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:uuid/uuid.dart';

class RealmOrganizeArguments {
  final Realm? edit;

  RealmOrganizeArguments({this.edit});
}

class RealmOrganizeScreen extends StatefulWidget {
  final Realm? edit;

  const RealmOrganizeScreen({super.key, this.edit});

  @override
  State<RealmOrganizeScreen> createState() => _RealmOrganizeScreenState();
}

class _RealmOrganizeScreenState extends State<RealmOrganizeScreen> {
  bool _isBusy = false;

  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isCommunity = false;
  bool _isPublic = false;

  void applyRealm() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    if (_aliasController.value.text.isEmpty) randomizeAlias();

    setState(() => _isBusy = true);

    final client = auth.configureClient(service: 'passport');

    final payload = {
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'is_public': _isPublic,
      'is_community': _isCommunity,
    };

    Response resp;
    if (widget.edit != null) {
      resp = await client.put('/api/realms/${widget.edit!.id}', payload);
    } else {
      resp = await client.post('/api/realms', payload);
    }
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isBusy = false);
  }

  void randomizeAlias() {
    _aliasController.text =
        const Uuid().v4().replaceAll('-', '').substring(0, 12);
  }

  void syncWidget() {
    if (widget.edit != null) {
      _aliasController.text = widget.edit!.alias;
      _nameController.text = widget.edit!.name;
      _descriptionController.text = widget.edit!.description;
      _isPublic = widget.edit!.isPublic;
      _isCommunity = widget.edit!.isCommunity;
    }
  }

  void cancelAction() {
    AppRouter.instance.pop();
  }

  @override
  void initState() {
    syncWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: Text('realmOrganizing'.tr),
          leading: const PrevPageButton(),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => applyRealm(),
              child: Text('apply'.tr.toUpperCase()),
            )
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
              if (widget.edit != null)
                MaterialBanner(
                  leading: const Icon(Icons.edit),
                  leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                  dividerColor: Colors.transparent,
                  content: Text(
                    'realmEditingNotify'
                        .trParams({'realm': '#${widget.edit!.alias}'}),
                  ),
                  actions: [
                    TextButton(
                      onPressed: cancelAction,
                      child: Text('cancel'.tr),
                    ),
                  ],
                ).paddingOnly(bottom: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _aliasController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'realmAlias'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                    ),
                    onPressed: () => randomizeAlias(),
                    child: const Icon(Icons.refresh),
                  )
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 2),
              const Divider(thickness: 0.3),
              TextField(
                autocorrect: true,
                controller: _nameController,
                decoration: InputDecoration.collapsed(
                  hintText: 'realmName'.tr,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ).paddingSymmetric(horizontal: 16, vertical: 8),
              const Divider(thickness: 0.3),
              Expanded(
                child: TextField(
                  minLines: 5,
                  maxLines: null,
                  autocorrect: true,
                  keyboardType: TextInputType.multiline,
                  controller: _descriptionController,
                  decoration: InputDecoration.collapsed(
                    hintText: 'realmDescription'.tr,
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ).paddingSymmetric(horizontal: 16, vertical: 12),
              ),
              const Divider(thickness: 0.3),
              CheckboxListTile(
                title: Text('realmPublic'.tr),
                value: _isPublic,
                onChanged: (newValue) =>
                    setState(() => _isPublic = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Text('realmCommunity'.tr),
                value: _isCommunity,
                onChanged: (newValue) =>
                    setState(() => _isCommunity = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
