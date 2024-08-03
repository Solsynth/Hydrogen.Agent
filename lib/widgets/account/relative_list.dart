import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';

class SilverRelativeList extends StatelessWidget {
  final List<Relationship> items;
  final Function onUpdate;
  final bool isHandleable;

  const SilverRelativeList({
    super.key,
    required this.items,
    required this.onUpdate,
    this.isHandleable = true,
  });

  Widget buildItem(context, index) {
    final element = items[index];
    return ListTile(
      title: Text(element.related.nick),
      subtitle: Text(element.related.name),
      leading: GestureDetector(
        child: AccountAvatar(content: element.related.avatar),
        onTap: () {
          showModalBottomSheet(
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .surface,
            context: context,
            builder: (context) =>
                AccountProfilePopup(
                  name: element.related.name,
                ),
          );
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(element.status != 1 && element.status != 3)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                final RelationshipProvider provider = Get.find();
                if (element.status == 0) {
                  provider.handleRelation(element, true).then((_) => onUpdate());
                } else {
                  provider.editRelation(element, 1).then((_) => onUpdate());
                }
              },
            ),
          if(element.status != 2 && element.status != 3)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                final RelationshipProvider provider = Get.find();
                if (element.status == 0) {
                  provider.handleRelation(element, false).then((_) => onUpdate());
                } else {
                  provider.editRelation(element, 2).then((_) => onUpdate());
                }
              },
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
