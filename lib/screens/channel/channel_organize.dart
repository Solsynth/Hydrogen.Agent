import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/root_container.dart';
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

  bool _isPublic = false;
  bool _isCommunity = false;

  void _applyChannel() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    if (_aliasController.value.text.isEmpty) _randomizeAlias();

    setState(() => _isBusy = true);

    final ChannelProvider provider = Get.find();

    final scope = widget.realm != null ? widget.realm!.alias : 'global';
    final payload = {
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'is_encrypted': _isPublic,
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

  void _randomizeAlias() {
    _aliasController.text =
        const Uuid().v4().replaceAll('-', '').substring(0, 12);
  }

  void _syncWidget() {
    if (widget.edit != null) {
      _aliasController.text = widget.edit!.alias;
      _nameController.text = widget.edit!.name;
      _descriptionController.text = widget.edit!.description;
      _isPublic = widget.edit!.isPublic;
      _isCommunity = widget.edit!.isCommunity;
    }
  }

  void _cancelAction() {
    AppRouter.instance.pop();
  }

  @override
  void initState() {
    _syncWidget();
    super.initState();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifyBannerActions = [
      TextButton(
        onPressed: _cancelAction,
        child: Text('cancel'.tr),
      ),
    ];

    return ResponsiveRootContainer(
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle('channelOrganizing'.tr),
          centerTitle: false,
          toolbarHeight: AppTheme.toolbarHeight(context),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => _applyChannel(),
              child: Text('apply'.tr.toUpperCase()),
            )
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              LoadingIndicator(isActive: _isBusy),
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
                    onPressed: () => _randomizeAlias(),
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
                title: Text('channelPublic'.tr),
                value: _isPublic,
                onChanged: (value) =>
                    setState(() => _isPublic = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Text('channelCommunity'.tr),
                value: _isCommunity,
                onChanged: (value) =>
                    setState(() => _isCommunity = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
