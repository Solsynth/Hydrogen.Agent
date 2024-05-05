import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/chat/chat_list.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/screens/realms/realm_member.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/scaffold.dart';

class RealmScreen extends StatelessWidget {
  final String alias;

  const RealmScreen({super.key, required this.alias});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final realm = context.watch<RealmProvider>();

    return IndentScaffold(
      title: realm.focusRealm?.name ?? 'Loading...',
      hideDrawer: true,
      noSafeArea: true,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      appBarActions: realm.focusRealm != null
          ? [
              RealmManageAction(
                realm: realm.focusRealm!,
                onUpdate: () => realm.fetchSingle(auth, alias),
              ),
            ]
          : [],
      appBarLeading: SolianTheme.isLargeScreen(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                realm.clearFocus();
              },
            )
          : null,
      child: RealmWidget(
        alias: alias,
      ),
    );
  }
}

class RealmWidget extends StatefulWidget {
  final String alias;

  const RealmWidget({super.key, required this.alias});

  @override
  State<RealmWidget> createState() => _RealmWidgetState();
}

class _RealmWidgetState extends State<RealmWidget> {
  bool _isReady = false;

  late RealmProvider _realm;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      final auth = context.read<AuthProvider>();
      if (_realm.focusRealm?.alias != widget.alias) {
        _realm.fetchSingle(auth, widget.alias);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      _realm = context.watch<RealmProvider>();
      _isReady = true;
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: !SolianTheme.isLargeScreen(context),
            tabs: const [
              Tab(icon: Icon(Icons.newspaper)),
              Tab(icon: Icon(Icons.message)),
              Tab(icon: Icon(Icons.supervisor_account))
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExplorePostWidget(realm: widget.alias),
                ChatListWidget(realm: widget.alias),
                _realm.focusRealm != null
                    ? RealmMemberWidget(realm: _realm.focusRealm!)
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class RealmManageAction extends StatelessWidget {
  final Realm realm;
  final Function onUpdate;

  const RealmManageAction({
    super.key,
    required this.realm,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final did = await SolianRouter.router.pushNamed(
          'realms.editor',
          extra: realm,
        );
        if (did == true) onUpdate();
      },
      icon: const Icon(Icons.settings),
    );
  }
}
