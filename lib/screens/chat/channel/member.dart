import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/account/avatar.dart';
import 'package:solian/widgets/account/friend_picker.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatMemberScreen extends StatefulWidget {
  final Channel channel;

  const ChatMemberScreen({super.key, required this.channel});

  @override
  State<ChatMemberScreen> createState() => _ChatMemberScreenState();
}

class _ChatMemberScreenState extends State<ChatMemberScreen> {
  bool _isSubmitting = false;

  List<ChannelMember> _members = List.empty();

  int _selfId = 0;

  Future<void> fetchMemberships() async {
    final auth = context.read<AuthProvider>();
    final prof = await auth.getProfiles();
    if (!await auth.isAuthorized()) return;

    _selfId = prof['id'];

    var uri = getRequestUri('messaging', '/api/channels/${widget.channel.alias}/members');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      setState(() {
        _members = result.map((x) => ChannelMember.fromJson(x)).toList();
      });
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    }
  }

  Future<void> kickMember(ChannelMember item) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.channel.alias}/kick');

    var res = await auth.client!.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'account_name': item.account.name,
      }),
    );
    if (res.statusCode == 200) {
      await fetchMemberships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> inviteMember(String username) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.channel.alias}/invite');

    var res = await auth.client!.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'account_name': username,
      }),
    );
    if (res.statusCode == 200) {
      await fetchMemberships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  void promptInviteMember() async {
    final input = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return const FriendPicker();
      },
    );
    if (input == null) return;

    await inviteMember((input as Account).name);
  }

  bool getKickable(ChannelMember item) {
    if (_selfId != widget.channel.account.externalId) return false;
    if (item.accountId == widget.channel.accountId) return false;
    if (item.account.externalId == _selfId) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () => fetchMemberships());
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      title: AppLocalizations.of(context)!.chatMember,
      noSafeArea: true,
      hideDrawer: true,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => promptInviteMember(),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => fetchMemberships(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
            ),
            SliverList.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final element = _members[index];

                final randomId = DateTime.now().microsecondsSinceEpoch >> 10;

                return Dismissible(
                  key: Key(randomId.toString()),
                  direction: getKickable(element) ? DismissDirection.startToEnd : DismissDirection.none,
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: AccountAvatar(source: element.account.avatar, direct: true),
                    title: Text(element.account.nick),
                    subtitle: Text(element.account.name),
                  ),
                  onDismissed: (_) {
                    kickMember(element);
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
