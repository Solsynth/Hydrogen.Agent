import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/realms/realm_organize.dart';
import 'package:solian/widgets/realms/realm_deletion.dart';
import 'package:solian/widgets/realms/realm_member.dart';
import 'package:solian/widgets/root_container.dart';

class RealmDetailScreen extends StatefulWidget {
  final String alias;
  final Realm realm;

  const RealmDetailScreen({
    super.key,
    required this.alias,
    required this.realm,
  });

  @override
  State<RealmDetailScreen> createState() => _RealmDetailScreenState();
}

class _RealmDetailScreenState extends State<RealmDetailScreen> {
  bool _isOwned = false;

  void checkOwner() async {
    final AuthProvider auth = Get.find();
    setState(() {
      _isOwned = auth.userProfile.value!['id'] == widget.realm.accountId;
    });
  }

  void showMemberList() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => RealmMemberListPopup(
        realm: widget.realm,
      ),
    );
  }

  void promptLeaveChannel() async {
    final did = await showDialog(
      context: context,
      builder: (context) => RealmDeletionDialog(
        realm: widget.realm,
        isOwned: _isOwned,
      ),
    );
    if (did == true && AppRouter.instance.canPop()) {
      AppRouter.instance.pop(false);
    }
  }

  @override
  void initState() {
    super.initState();

    checkOwner();
  }

  @override
  Widget build(BuildContext context) {
    final ownerActions = [
      ListTile(
        leading: const Icon(Icons.settings),
        trailing: const Icon(Icons.chevron_right),
        title: Text('realmSettings'.tr),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        onTap: () async {
          AppRouter.instance
              .pushNamed(
            'realmOrganizing',
            extra: RealmOrganizeArguments(edit: widget.realm),
          )
              .then((resp) {
            if (resp != null) {
              AppRouter.instance.pop(resp);
            }
          });
        },
      ),
    ];

    return RootContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.group, color: Colors.white),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.realm.name,
                          style: Theme.of(context).textTheme.bodyLarge),
                      Text(widget.realm.description,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '#${widget.realm.id.toString().padLeft(8, '0')} · ${widget.realm.alias}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(thickness: 0.3),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.supervisor_account),
                  trailing: const Icon(Icons.chevron_right),
                  title: Text('realmMembers'.tr),
                  onTap: () => showMemberList(),
                ),
                ...(_isOwned ? ownerActions : List.empty()),
                const Divider(thickness: 0.3),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: _isOwned
                      ? const Icon(Icons.delete)
                      : const Icon(Icons.exit_to_app),
                  title: Text(_isOwned ? 'delete'.tr : 'leave'.tr),
                  onTap: () => promptLeaveChannel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
