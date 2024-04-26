import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatCall extends StatefulWidget {
  final Call call;

  const ChatCall({super.key, required this.call});

  @override
  State<ChatCall> createState() => _ChatCallState();
}

class _ChatCallState extends State<ChatCall> {
  String? _token;

  Future<String> exchangeToken() async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      router.pop();
      throw Error();
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.call.channel.alias}/calls/ongoing/token');

    var res = await auth.client!.post(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      _token = result['token'];
      return _token!;
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
      throw Exception(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      title: AppLocalizations.of(context)!.chatCall,
      noSafeArea: true,
      hideDrawer: true,
      child: FutureBuilder(
        future: exchangeToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          print(snapshot.data!);
          return Container();
        },
      ),
    );
  }
}
