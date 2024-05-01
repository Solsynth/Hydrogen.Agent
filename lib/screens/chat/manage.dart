import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/chat/channel_deletion.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatManageScreen extends StatefulWidget {
  final Channel channel;

  const ChatManageScreen({super.key, required this.channel});

  @override
  State<ChatManageScreen> createState() => _ChatManageScreenState();
}

class _ChatManageScreenState extends State<ChatManageScreen> {
  bool _isOwned = false;

  void promptLeaveChannel() async {
    final did = await showDialog(
      context: context,
      builder: (context) => ChannelDeletion(
        channel: widget.channel,
        isOwned: _isOwned,
      ),
    );
    if (did == true && router.canPop()) {
      router.pop('disposed');
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final auth = context.read<AuthProvider>();
      final prof = await auth.getProfiles();

      setState(() {
        _isOwned = prof['id'] == widget.channel.account.externalId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authorizedItems = [
      ListTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.settings),
        onTap: () async {
          router
              .pushNamed('chat.channel.editor', extra: widget.channel)
              .then((did) {
            if (did == true) {
              if (router.canPop()) router.pop('refresh');
            }
          });
        },
      ),
    ];

    return IndentWrapper(
      title: AppLocalizations.of(context)!.chatManage,
      hideDrawer: true,
      noSafeArea: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.tag, color: Colors.white),
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
                      ]),
                )
              ],
            ),
          ),
          const Divider(thickness: 0.3),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_notifications),
                  title: Text(AppLocalizations.of(context)!.chatNotifySetting),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.supervisor_account),
                  title: Text(AppLocalizations.of(context)!.chatMember),
                  onTap: () {
                    router.pushNamed(
                      'chat.channel.member',
                      extra: widget.channel,
                      pathParameters: {'channel': widget.channel.alias},
                    );
                  },
                ),
                ...(_isOwned ? authorizedItems : List.empty()),
                const Divider(thickness: 0.3),
                ListTile(
                  leading: _isOwned
                      ? const Icon(Icons.delete)
                      : const Icon(Icons.exit_to_app),
                  title: Text(_isOwned
                      ? AppLocalizations.of(context)!.delete
                      : AppLocalizations.of(context)!.exit),
                  onTap: () => promptLeaveChannel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
