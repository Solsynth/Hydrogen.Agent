import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class FriendSelect extends StatefulWidget {
  final String title;
  final Widget? Function(Account item)? trailingBuilder;

  const FriendSelect({super.key, required this.title, this.trailingBuilder});

  @override
  State<FriendSelect> createState() => _FriendSelectState();
}

class _FriendSelectState extends State<FriendSelect> {
  int _accountId = 0;

  List<Friendship> _friends = List.empty(growable: true);

  getFriends() async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    _accountId = prof.body['id'];

    final FriendProvider provider = Get.find();
    final resp = await provider.listFriendshipWithStatus(1);

    setState(() {
      _friends.addAll(resp.body
          .map((e) => Friendship.fromJson(e))
          .toList()
          .cast<Friendship>());
    });
  }

  @override
  void initState() {
    super.initState();

    getFriends();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                var element = _friends[index].getOtherside(_accountId);
                return ListTile(
                  title: Text(element.nick),
                  subtitle: Text(element.name),
                  leading: AccountAvatar(content: element.avatar),
                  trailing: widget.trailingBuilder != null
                      ? widget.trailingBuilder!(element)
                      : null,
                  onTap: () {
                    Navigator.pop(context, element);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
