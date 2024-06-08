import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/widgets/channel/channel_deletion.dart';
import 'package:solian/widgets/channel/channel_member.dart';

class ChannelDetailArguments {
  final Channel channel;
  final ChannelMember profile;

  ChannelDetailArguments({required this.channel, required this.profile});
}

class ChannelDetailScreen extends StatefulWidget {
  final String realm;
  final Channel channel;
  final ChannelMember profile;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
    required this.realm,
    required this.profile,
  });

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  bool _isBusy = false;

  bool _isOwned = false;
  int _notifyLevel = 0;

  void checkOwner() async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    setState(() {
      _isOwned = prof.body['id'] == widget.channel.account.externalId;
    });
  }

  void showMemberList() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => ChannelMemberListPopup(
        channel: widget.channel,
        realm: widget.realm,
      ),
    );
  }

  void promptLeaveChannel() async {
    final did = await showDialog(
      context: context,
      builder: (context) => ChannelDeletionDialog(
        channel: widget.channel,
        realm: widget.realm,
        isOwned: _isOwned,
      ),
    );
    if (did == true && AppRouter.instance.canPop()) {
      AppRouter.instance.pop(false);
    }
  }

  void applyProfileChanges() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = auth.configureClient(service: 'messaging');

    final resp = await client
        .put('/api/channels/${widget.realm}/${widget.channel.alias}/members/me', {
      'nick': null,
      'notify_level': _notifyLevel,
    });
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      context.showSnackbar('channelNotifyLevelApplied'.tr);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    _notifyLevel = widget.profile.notify;
    super.initState();
    checkOwner();
  }

  @override
  Widget build(BuildContext context) {
    final notifyTypes = {
      0: 'channelNotifyLevelAll'.tr,
      1: 'channelNotifyLevelMentioned'.tr,
      2: 'channelNotifyLevelNone'.tr,
    };

    final ownerActions = [
      ListTile(
        leading: const Icon(Icons.edit),
        trailing: const Icon(Icons.chevron_right),
        title: Text('channelAdjust'.tr.capitalize!),
        onTap: () async {
          AppRouter.instance
              .pushNamed(
            'channelOrganizing',
            extra: ChannelOrganizeArguments(edit: widget.channel),
          )
              .then((resp) {
            if (resp != null) {
              AppRouter.instance.pop(resp);
            }
          });
        },
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal,
                child: FaIcon(
                  FontAwesomeIcons.hashtag,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.channel.name,
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text(widget.channel.description,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '#${widget.channel.id.toString().padLeft(8, '0')} · ${widget.channel.alias}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const Divider(thickness: 0.3),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: Text('channelNotifyLevel'.tr.capitalize!),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton2<int>(
                    isExpanded: true,
                    items: notifyTypes.entries
                        .map((item) => DropdownMenuItem<int>(
                      enabled: !_isBusy,
                              value: item.key,
                              child: Text(
                                item.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                    value: _notifyLevel,
                    onChanged: (int? value) {
                      setState(() => _notifyLevel = value ?? 0);
                      applyProfileChanges();
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
              ListTile(
                leading: const Icon(Icons.supervisor_account),
                trailing: const Icon(Icons.chevron_right),
                title: Text('channelMembers'.tr.capitalize!),
                onTap: () => showMemberList(),
              ),
              ...(_isOwned ? ownerActions : List.empty()),
              const Divider(thickness: 0.3),
              ListTile(
                leading: _isOwned
                    ? const Icon(Icons.delete)
                    : const Icon(Icons.exit_to_app),
                title: Text(_isOwned ? 'delete'.tr : 'leave'.tr),
                onTap: () => promptLeaveChannel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
