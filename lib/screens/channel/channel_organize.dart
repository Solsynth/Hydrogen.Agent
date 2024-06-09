import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:uuid/uuid.dart';

class ChannelOrganizeArguments {
  final Channel? edit;
  final Realm? realm;

  ChannelOrganizeArguments({this.edit, this.realm});
}

class ChannelOrganizeScreen extends StatefulWidget {
  final Channel? edit;
  final Realm? realm;

  const ChannelOrganizeScreen({super.key, this.edit, this.realm});

  @override
  State<ChannelOrganizeScreen> createState() => _ChannelOrganizeScreenState();
}

class _ChannelOrganizeScreenState extends State<ChannelOrganizeScreen> {
  bool _isBusy = false;

  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEncrypted = false;

  void applyChannel() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    if (_aliasController.value.text.isEmpty) randomizeAlias();

    setState(() => _isBusy = true);

    final ChannelProvider provider = Get.find();

    final scope = widget.realm != null ? widget.realm!.alias : 'global';
    final payload = {
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'is_encrypted': _isEncrypted,
    };

    Response? resp;
    try {
      if (widget.edit != null) {
        resp = await provider.updateChannel(scope, widget.edit!.id, payload);
      } else {
        resp = await provider.createChannel(scope, payload);
      }
    } catch (e) {
      context.showErrorDialog(e);
    }

    AppRouter.instance.pop(resp!.body);

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
      _isEncrypted = widget.edit!.isEncrypted;
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
    final notifyBannerActions = [
      TextButton(
        onPressed: cancelAction,
        child: Text('cancel'.tr),
      ),
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: Text('channelOrganizing'.tr),
          leading: const PrevPageButton(),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => applyChannel(),
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
                    'channelEditingNotify'
                        .trParams({'channel': '#${widget.edit!.alias}'}),
                  ),
                  actions: notifyBannerActions,
                ).paddingOnly(bottom: 6),
              if (widget.realm != null && widget.edit == null)
                MaterialBanner(
                  leading: const Icon(Icons.group),
                  leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                  dividerColor: Colors.transparent,
                  content: Text(
                    'channelInRealmNotify'
                        .trParams({'realm': '#${widget.realm!.alias}'}),
                  ),
                  actions: notifyBannerActions,
                ).paddingOnly(bottom: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _aliasController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'channelAlias'.tr,
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
                  hintText: 'channelName'.tr,
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
                    hintText: 'channelDescription'.tr,
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ).paddingSymmetric(horizontal: 16, vertical: 12),
              ),
              const Divider(thickness: 0.3),
              CheckboxListTile(
                title: Text('channelEncrypted'.tr),
                value: _isEncrypted,
                onChanged: (widget.edit?.isEncrypted ?? false)
                    ? null
                    : (newValue) =>
                        setState(() => _isEncrypted = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
