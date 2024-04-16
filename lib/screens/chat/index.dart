import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatIndexScreen extends StatefulWidget {
  const ChatIndexScreen({super.key});

  @override
  State<ChatIndexScreen> createState() => _ChatIndexScreenState();
}

class _ChatIndexScreenState extends State<ChatIndexScreen> {
  List<Channel> _channels = List.empty();

  Future<void> fetchChannels(BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      fetchChannels(context);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      title: AppLocalizations.of(context)!.chat,
      child: RefreshIndicator(
        onRefresh: () => fetchChannels(context),
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
              onTap: () {},
            );
          },
        ),
      ),
    );
  }
}
