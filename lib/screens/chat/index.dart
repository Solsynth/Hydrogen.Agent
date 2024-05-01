import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/chat/chat.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/chat/chat_new.dart';
import 'package:solian/widgets/empty.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/notification_notifier.dart';
import 'package:solian/widgets/signin_required.dart';

class ChatIndexScreen extends StatefulWidget {
  const ChatIndexScreen({super.key});

  @override
  State<ChatIndexScreen> createState() => _ChatIndexScreenState();
}

class _ChatIndexScreenState extends State<ChatIndexScreen> {
  Channel? _selectedChannel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    return IndentWrapper(
      title: AppLocalizations.of(context)!.chat,
      appBarActions: const [NotificationButton()],
      fixedAppBarColor: isLargeScreen,
      child: isLargeScreen
          ? Row(
              children: [
                Flexible(
                  flex: 2,
                  child: ChatIndexScreenWidget(
                    onSelect: (item) {
                      setState(() => _selectedChannel = item);
                    },
                  ),
                ),
                const VerticalDivider(thickness: 0.3, width: 0.3),
                Flexible(
                  flex: 4,
                  child: _selectedChannel == null
                      ? const SelectionEmptyWidget()
                      : ChatScreenWidget(
                          key: Key('c${_selectedChannel!.id}'),
                          alias: _selectedChannel!.alias,
                        ),
                ),
              ],
            )
          : ChatIndexScreenWidget(
              onSelect: (item) async {
                final result = await router.pushNamed(
                  'chat.channel',
                  pathParameters: {
                    'channel': item.alias,
                  },
                );
                switch (result) {
                  case 'refresh':
                  // fetchChannels();
                }
              },
            ),
    );
  }
}

class ChatIndexScreenWidget extends StatefulWidget {
  final Function(Channel item) onSelect;

  const ChatIndexScreenWidget({super.key, required this.onSelect});

  @override
  State<ChatIndexScreenWidget> createState() => _ChatIndexScreenWidgetState();
}

class _ChatIndexScreenWidgetState extends State<ChatIndexScreenWidget> {
  List<Channel> _channels = List.empty();

  Future<void> fetchChannels() async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    var uri = getRequestUri('messaging', '/api/channels/me/available');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      setState(() {
        _channels = result.map((x) => Channel.fromJson(x)).toList();
      });
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }
  }

  void viewNewChatAction() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ChatNewAction(onUpdate: () => fetchChannels()),
    );
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      fetchChannels();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      floatingActionButton: FutureBuilder(
        future: auth.isAuthorized(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.chatNew),
              onPressed: () => viewNewChatAction(),
            );
          } else {
            return Container();
          }
        },
      ),
      body: FutureBuilder(
        future: auth.isAuthorized(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!) {
            return const SignInRequiredScreen();
          }

          return RefreshIndicator(
            onRefresh: () => fetchChannels(),
            child: ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final element = _channels[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.tag, color: Colors.white),
                  ),
                  title: Text(element.name),
                  subtitle: Text(element.description),
                  onTap: () => widget.onSelect(element),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
