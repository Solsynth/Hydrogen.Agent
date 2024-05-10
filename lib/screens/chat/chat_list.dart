import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/chat/chat_new.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/notification_notifier.dart';
import 'package:solian/widgets/signin_required.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: AppLocalizations.of(context)!.chat,
      appBarActions: const [NotificationButton()],
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      body: const ChatListWidget(),
    );
  }
}

class ChatListWidget extends StatefulWidget {
  final String? realm;

  const ChatListWidget({super.key, this.realm});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  List<Channel> _channels = List.empty();

  Future<void> fetchChannels() async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    Uri uri;
    if (widget.realm == null) {
      uri = getRequestUri('messaging', '/api/channels/global/me/available');
    } else {
      uri = getRequestUri('messaging', '/api/channels/${widget.realm}');
    }

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
      builder: (context) => ChatNewAction(
        onUpdate: () => fetchChannels(),
        realm: widget.realm,
      ),
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
    final chat = context.watch<ChatProvider>();

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
                  onTap: () async {
                    String? result;
                    if (['chat.channel', 'realms.chat.channel'].contains(SolianRouter.currentRoute.name)) {
                      chat.fetchChannel(context, auth, element.alias, widget.realm!);
                    } else {
                      result = await SolianRouter.router.pushNamed(
                        widget.realm == null ? 'chat.channel' : 'realms.chat.channel',
                        pathParameters: {
                          'channel': element.alias,
                          ...(widget.realm == null ? {} : {'realm': widget.realm!}),
                        },
                      );
                    }
                    switch (result) {
                      case 'refresh':
                        fetchChannels();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
