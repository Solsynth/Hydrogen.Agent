import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/widgets/channel/channel_deletion.dart';
import 'package:solian/widgets/channel/channel_member.dart';

class ChannelDetailScreen extends StatefulWidget {
  final String realm;
  final Channel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
    required this.realm,
  });

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  bool _isOwned = false;

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

  @override
  void initState() {
    super.initState();

    checkOwner();
  }

  @override
  Widget build(BuildContext context) {
    final ownerActions = [
      ListTile(
        leading: const Icon(Icons.edit),
        trailing: const Icon(Icons.chevron_right),
        title: Text('channelAdjust'.tr),
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
                leading: const Icon(Icons.settings),
                trailing: const Icon(Icons.chevron_right),
                title: Text('channelSettings'.tr),
              ),
              ListTile(
                leading: const Icon(Icons.supervisor_account),
                trailing: const Icon(Icons.chevron_right),
                title: Text('channelMembers'.tr),
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
