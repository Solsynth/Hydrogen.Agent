import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/friend.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/account/avatar.dart';

class FriendPicker extends StatefulWidget {
  const FriendPicker({super.key});

  @override
  State<FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<FriendPicker> {
  int _selfId = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final auth = context.read<AuthProvider>();
      final friends = context.read<FriendProvider>();
      friends.fetch(auth);

      final prof = await auth.getProfiles();
      _selfId = prof['id'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final dict = context.watch<FriendProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.friend,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dict.friends.length,
            itemBuilder: (context, index) {
              var element = dict.friends[index].getOtherside(_selfId);
              return ListTile(
                title: Text(element.nick),
                subtitle: Text(element.name),
                leading: AccountAvatar(source: element.avatar),
                onTap: () {
                  Navigator.pop(context, element);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
