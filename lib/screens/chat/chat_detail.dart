import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/chat/channel_deletion.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatDetailScreen extends StatefulWidget {
  final Channel channel;
  final String realm;

  const ChatDetailScreen({super.key, required this.channel, this.realm = 'global'});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  bool _isOwned = false;

  void promptLeaveChannel() async {
    final did = await showDialog(
      context: context,
      builder: (context) =>
          ChannelDeletion(
            channel: widget.channel,
            realm: widget.realm,
            isOwned: _isOwned,
          ),
    );
    if (did == true && SolianRouter.router.canPop()) {
      SolianRouter.router.pop('disposed');
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
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    final authorizedItems = [
      ListTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.settings),
        onTap: () async {
          SolianRouter.router
              .pushNamed(
            'chat.channel.editor',
            extra: widget.channel,
            queryParameters: widget.realm != 'global' ? {'realm': widget.realm} : {},
          )
              .then((resp) {
            if (resp != null) {
              chat.fetchChannel(context, auth, resp as String, widget.realm);
            }
          });
        },
      ),
    ];

    return IndentScaffold(
      title: AppLocalizations.of(context)!.chatDetail,
      hideDrawer: true,
      body: Column(
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.channel.name, style: Theme
                        .of(context)
                        .textTheme
                        .bodyLarge),
                    Text(widget.channel.description, style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall),
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
                    SolianRouter.router.pushNamed(
                      widget.realm == 'global' ? 'chat.channel.member' : 'realms.chat.channel.member',
                      extra: widget.channel,
                      pathParameters: {
                        'channel': widget.channel.alias,
                        ...(widget.realm == 'global' ? {} : {'realm': widget.realm}),
                      },
                    );
                  },
                ),
                ...(_isOwned ? authorizedItems : List.empty()),
                const Divider(thickness: 0.3),
                ListTile(
                  leading: _isOwned ? const Icon(Icons.delete) : const Icon(Icons.exit_to_app),
                  title: Text(_isOwned ? AppLocalizations.of(context)!.delete : AppLocalizations.of(context)!.exit),
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
