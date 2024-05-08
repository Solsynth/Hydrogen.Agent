import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/realms/realm.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/notification_notifier.dart';
import 'package:solian/widgets/realms/realm_new.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/signin_required.dart';

class RealmListScreen extends StatelessWidget {
  const RealmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final realm = context.watch<RealmProvider>();

    return realm.focusRealm == null || !SolianTheme.isLargeScreen(context)
        ? IndentScaffold(
            title: AppLocalizations.of(context)!.realm,
            appBarActions: const [NotificationButton()],
            fixedAppBarColor: SolianTheme.isLargeScreen(context),
            body: const RealmListWidget(),
          )
        : RealmScreen(alias: realm.focusRealm!.alias);
  }
}

class RealmListWidget extends StatefulWidget {
  const RealmListWidget({super.key});

  @override
  State<RealmListWidget> createState() => _RealmListWidgetState();
}

class _RealmListWidgetState extends State<RealmListWidget> {
  void viewNewRealmAction() {
    final auth = context.read<AuthProvider>();
    final realms = context.read<RealmProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => RealmNewAction(onUpdate: () => realms.fetch(auth)),
    );
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final auth = context.read<AuthProvider>();
      final realms = context.read<RealmProvider>();
      realms.fetch(auth);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final realms = context.watch<RealmProvider>();

    return Scaffold(
      floatingActionButton: FutureBuilder(
        future: auth.isAuthorized(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.realmNew),
              onPressed: () => viewNewRealmAction(),
            );
          } else {
            return Container();
          }
        },
      ),
      body: FutureBuilder(
        future: auth.isAuthorized(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!) {
            return const SignInRequiredScreen();
          }

          return RefreshIndicator(
            onRefresh: () => realms.fetch(auth),
            child: ListView.builder(
              itemCount: realms.realms.length,
              itemBuilder: (context, index) {
                final element = realms.realms[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.supervisor_account, color: Colors.white),
                  ),
                  title: Text(element.name),
                  subtitle: Text(element.description),
                  onTap: () async {
                    realms.fetchSingle(auth, element.alias);
                    String? result;
                    if (SolianRouter.currentRoute.name == 'chat.channel') {
                      result = await SolianRouter.router.pushReplacementNamed(
                        'realms.details',
                        pathParameters: {
                          'realm': element.alias,
                        },
                      );
                    } else {
                      result = await SolianRouter.router.pushNamed(
                        'realms.details',
                        pathParameters: {
                          'realm': element.alias,
                        },
                      );
                    }
                    switch (result) {
                      case 'refresh':
                        realms.fetch(auth);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
