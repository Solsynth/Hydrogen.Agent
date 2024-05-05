import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/friend_picker.dart';
import 'package:solian/widgets/exts.dart';

class RealmMemberWidget extends StatefulWidget {
  final Realm realm;

  const RealmMemberWidget({super.key, required this.realm});

  @override
  State<RealmMemberWidget> createState() => _RealmMemberWidgetState();
}

class _RealmMemberWidgetState extends State<RealmMemberWidget> {
  bool _isSubmitting = false;

  List<RealmMember> _members = List.empty();

  int _selfId = 0;

  Future<void> fetchMemberships() async {
    final auth = context.read<AuthProvider>();
    final prof = await auth.getProfiles();
    if (!await auth.isAuthorized()) return;

    _selfId = prof['id'];

    var uri = getRequestUri('passport', '/api/realms/${widget.realm.alias}/members');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      setState(() {
        _members = result.map((x) => RealmMember.fromJson(x)).toList();
      });
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }
  }

  Future<void> removeMember(RealmMember item) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('passport', '/api/realms/${widget.realm.alias}/members');

    var res = await auth.client!.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'target': item.account.name,
      }),
    );
    if (res.statusCode == 200) {
      await fetchMemberships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> addMember(String username) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('passport', '/api/realms/${widget.realm.alias}/members');

    var res = await auth.client!.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'target': username,
      }),
    );
    if (res.statusCode == 200) {
      await fetchMemberships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  void promptAddMember() async {
    final input = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return const FriendPicker();
      },
    );
    if (input == null) return;

    await addMember((input as Account).name);
  }

  bool getRemovable(RealmMember item) {
    if (_selfId != widget.realm.accountId) return false;
    if (item.accountId == widget.realm.accountId) return false;
    if (item.account.id == _selfId) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () => fetchMemberships());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => promptAddMember(),
      ),
      body: RefreshIndicator(
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
                  direction: getRemovable(element) ? DismissDirection.startToEnd : DismissDirection.none,
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: AccountAvatar(source: element.account.avatar),
                    title: Text(element.account.nick),
                    subtitle: Text(element.account.name),
                  ),
                  onDismissed: (_) {
                    removeMember(element);
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
