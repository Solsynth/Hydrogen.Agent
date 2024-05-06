import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/realms/realm_deletion.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RealmManageScreen extends StatefulWidget {
  final Realm realm;

  const RealmManageScreen({super.key, required this.realm});

  @override
  State<RealmManageScreen> createState() => _RealmManageScreenState();
}

class _RealmManageScreenState extends State<RealmManageScreen> {
  bool _isOwned = false;

  void promptLeaveChannel() async {
    final did = await showDialog(
      context: context,
      builder: (context) => RealmDeletion(
        realm: widget.realm,
        isOwned: _isOwned,
      ),
    );
    if (did == true && SolianRouter.router.canPop()) {
      SolianRouter.router.pop('disposed');
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final auth = context.read<AuthProvider>();
      final prof = await auth.getProfiles();

      setState(() {
        _isOwned = prof['id'] == widget.realm.accountId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authorizedItems = [
      ListTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.settings),
        onTap: () async {
          SolianRouter.router.pushNamed('realms.editor', extra: widget.realm).then((did) {
            if (did == true) {
              if (SolianRouter.router.canPop()) SolianRouter.router.pop('refresh');
            }
          });
        },
      ),
    ];

    return IndentScaffold(
      title: AppLocalizations.of(context)!.realmManage,
      hideDrawer: true,
      noSafeArea: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.tag, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.realm.name, style: Theme.of(context).textTheme.bodyLarge),
                    Text(widget.realm.description, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                )
              ],
            ),
          ),
          const Divider(thickness: 0.3),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.supervisor_account),
                  title: Text(AppLocalizations.of(context)!.chatMember),
                  onTap: () {
                    SolianRouter.router.pushNamed(
                      'realms.member',
                      extra: widget.realm,
                      pathParameters: {'realm': widget.realm.alias},
                    );
                  },
                ),
                ...(_isOwned ? authorizedItems : List.empty()),
                const Divider(thickness: 0.3),
                ListTile(
                  leading: _isOwned ? const Icon(Icons.delete) : const Icon(Icons.exit_to_app),
                  title: Text(_isOwned ? AppLocalizations.of(context)!.delete : AppLocalizations.of(context)!.exit),
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
