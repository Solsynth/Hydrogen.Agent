import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class SliverFriendList extends StatelessWidget {
  final int accountId;
  final List<Friendship> items;
  final Function onUpdate;

  const SliverFriendList({
    super.key,
    required this.accountId,
    required this.items,
    required this.onUpdate,
  });

  DismissDirection getDismissDirection(Friendship relation) {
    if (relation.status == 2) return DismissDirection.endToStart;
    if (relation.status == 1) return DismissDirection.startToEnd;
    if (relation.status == 0 && relation.relatedId != accountId) {
      return DismissDirection.startToEnd;
    }
    return DismissDirection.horizontal;
  }

  Widget buildItem(context, index) {
    final element = items[index];
    final otherside = element.getOtherside(accountId);

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
        leading: AccountAvatar(content: otherside.avatar),
      ),
      onDismissed: (direction) {
        final FriendProvider provider = Get.find();
        if (direction == DismissDirection.startToEnd) {
          provider.updateFriendship(element, 2).then((_) => onUpdate());
        }
        if (direction == DismissDirection.endToStart) {
          provider.updateFriendship(element, 1).then((_) => onUpdate());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, idx) => buildItem(context, idx),
    );
  }
}
