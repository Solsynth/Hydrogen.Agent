import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/account/avatar.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  bool _isSubmitting = false;

  int _selfId = 0;
  List<Friendship> _friendships = List.empty();

  Future<void> fetchFriendships() async {
    final auth = context.read<AuthProvider>();
    final prof = await auth.getProfiles();
    if (!await auth.isAuthorized()) return;

    _selfId = prof['id'];

    var uri = getRequestUri('passport', '/api/users/me/friends');

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      setState(() {
        _friendships = result.map((x) => Friendship.fromJson(x)).toList();
      });
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }
  }

  Future<void> createFriendship(String username) async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var res = await auth.client!.post(
      getRequestUri('passport', '/api/users/me/friends?related=$username'),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.friendAddDone)),
      );
      await fetchFriendships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> updateFriendship(Friendship relation, int status) async {
    setState(() => _isSubmitting = true);

    final otherside = relation.getOtherside(_selfId);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var res = await auth.client!.put(
      getRequestUri('passport', '/api/users/me/friends/${otherside.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'status': status,
      }),
    );
    if (res.statusCode == 200) {
      await fetchFriendships();
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  void promptAddFriend() async {
    final controller = TextEditingController();
    final input = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.friendAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.friendAddHint),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.account_circle),
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)!.username,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.next),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    await createFriendship(input);
  }

  List<Friendship> filterWithStatus(int status) {
    return _friendships.where((x) => x.status == status).toList();
  }

  DismissDirection getDismissDirection(Friendship relation) {
    if (relation.status == 2) return DismissDirection.endToStart;
    if (relation.status == 1) return DismissDirection.startToEnd;
    if (relation.status == 0 && relation.relatedId != _selfId)
      return DismissDirection.startToEnd;
    return DismissDirection.horizontal;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      fetchFriendships();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget friendshipTileBuilder(context, index, status) {
      final element = filterWithStatus(status)[index];
      final otherside = element.getOtherside(_selfId);

      final randomId = DateTime.now().microsecondsSinceEpoch >> 10;

      return Dismissible(
        key: Key(randomId.toString()),
        background: Container(
          color: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: const Icon(Icons.close, color: Colors.white),
        ),
        secondaryBackground: Container(
          color: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          child: const Icon(Icons.check, color: Colors.white),
        ),
        direction: getDismissDirection(element),
        child: ListTile(
          title: Text(otherside.nick),
          subtitle: Text(otherside.name),
          leading: AccountAvatar(source: otherside.avatar),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            updateFriendship(element, 2);
          }
          if (direction == DismissDirection.endToStart) {
            updateFriendship(element, 1);
          }
        },
      );
    }

    return IndentWrapper(
      title: AppLocalizations.of(context)!.friend,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => promptAddFriend(),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => fetchFriendships(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _isSubmitting
                  ? const LinearProgressIndicator().animate().scaleX()
                  : Container(),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.8),
                child: Text(AppLocalizations.of(context)!.friendPending),
              ),
            ),
            SliverList.builder(
              itemCount: filterWithStatus(0).length,
              itemBuilder: (_, __) => friendshipTileBuilder(_, __, 0),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.8),
                child: Text(AppLocalizations.of(context)!.friendActive),
              ),
            ),
            SliverList.builder(
              itemCount: filterWithStatus(1).length,
              itemBuilder: (_, __) => friendshipTileBuilder(_, __, 1),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.8),
                child: Text(AppLocalizations.of(context)!.friendBlocked),
              ),
            ),
            SliverList.builder(
              itemCount: filterWithStatus(2).length,
              itemBuilder: (_, __) => friendshipTileBuilder(_, __, 2),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.8),
                    width: 0.3,
                  )),
                ),
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  AppLocalizations.of(context)!.friendListHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
