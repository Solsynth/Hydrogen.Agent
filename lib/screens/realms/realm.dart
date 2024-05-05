import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/realm.dart';
import 'package:solian/screens/chat/chat_list.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/scaffold.dart';

class RealmScreen extends StatelessWidget {
  final String alias;

  const RealmScreen({super.key, required this.alias});

  @override
  Widget build(BuildContext context) {
    final realm = context.watch<RealmProvider>();

    return IndentScaffold(
      title: realm.focusRealm?.name ?? 'Loading...',
      hideDrawer: !SolianTheme.isLargeScreen(context),
      noSafeArea: true,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
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
      length: 2,
      child: Column(
        children: [
          TabBar(
            isScrollable: !SolianTheme.isLargeScreen(context),
            tabs: const [
              Tab(icon: Icon(Icons.newspaper)),
              Tab(icon: Icon(Icons.message)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExplorePostWidget(realm: widget.alias),
                ChatListWidget(realm: widget.alias),
              ],
            ),
          )
        ],
      ),
    );
  }
}
