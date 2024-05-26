import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/friend_select.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:uuid/uuid.dart';

class ChannelOrganizeArguments {
  final Channel? edit;

  ChannelOrganizeArguments({this.edit});
}

class ChannelOrganizeScreen extends StatefulWidget {
  final Channel? edit;
  final String? realm;

  const ChannelOrganizeScreen({super.key, this.edit, this.realm});

  @override
  State<ChannelOrganizeScreen> createState() => _ChannelOrganizeScreenState();
}

class _ChannelOrganizeScreenState extends State<ChannelOrganizeScreen> {
  static Map<int, String> channelTypes = {
    0: 'channelTypeCommon'.tr,
    1: 'channelTypeDirect'.tr,
  };

  bool _isBusy = false;

  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEncrypted = false;
  int _channelType = 0;

  List<Account> _initialMembers = List.empty(growable: true);

  void selectInitialMembers() async {
    final input = await showModalBottomSheet(
      useRootNavigator: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => FriendSelect(
        title: 'channelMember'.tr,
        trailingBuilder: (item) {
          if (_initialMembers.any((e) => e.id == item.id)) {
            return const Icon(Icons.check);
          } else {
            return null;
          }
        },
      ),
    );
    if (input == null) return;

    setState(() {
      if (_initialMembers.any((e) => e.id == input.id)) {
        _initialMembers = _initialMembers
            .where((e) => e.id != input.id)
            .toList(growable: true);
      } else {
        _initialMembers.add(input as Account);
      }
    });
  }

  void applyChannel() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    if (_aliasController.value.text.isEmpty) randomizeAlias();

    setState(() => _isBusy = true);

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final scope = (widget.realm?.isNotEmpty ?? false) ? widget.realm : 'global';
    final payload = {
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'is_encrypted': _isEncrypted,
      if (_channelType == 1)
        'members': _initialMembers.map((e) => e.id).toList(),
    };

    Response resp;
    if (widget.edit != null) {
      resp = await client.put(
        '/api/channels/$scope/${widget.edit!.id}',
        payload,
      );
    } else if (_channelType == 1) {
      resp = await client.post('/api/channels/$scope/dm', payload);
    } else {
      resp = await client.post('/api/channels/$scope', payload);
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
      _isEncrypted = widget.edit!.isEncrypted;
      _channelType = widget.edit!.type;
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
                  actions: [
                    TextButton(
                      onPressed: cancelAction,
                      child: Text('cancel'.tr),
                    ),
                  ],
                ),
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
              if (_channelType == 1)
                ListTile(
                  leading: const Icon(Icons.supervisor_account)
                      .paddingSymmetric(horizontal: 8),
                  title: Text('channelMember'.tr),
                  subtitle: _initialMembers.isNotEmpty
                      ? Text(_initialMembers.map((e) => e.name).join(' '))
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => selectInitialMembers(),
                ).animate().fadeIn().slideY(
                      begin: 1,
                      end: 0,
                      curve: Curves.fastEaseInToSlowEaseOut,
                    ),
              ListTile(
                leading: const Icon(Icons.mode).paddingSymmetric(horizontal: 8),
                title: Text('channelType'.tr),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton2<int>(
                    isExpanded: true,
                    items: channelTypes.entries
                        .map((item) => DropdownMenuItem<int>(
                              value: item.key,
                              child: Text(
                                item.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                    value: _channelType,
                    onChanged: (int? value) {
                      setState(() => _channelType = value ?? 0);
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.only(left: 16, right: 1),
                      height: 40,
                      width: 140,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                    ),
                  ),
                ),
              ),
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
