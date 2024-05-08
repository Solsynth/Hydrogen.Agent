import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RealmShortcuts extends StatelessWidget {
  const RealmShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final realm = context.watch<RealmProvider>();

    if (realm.realms.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: Text(
              AppLocalizations.of(context)!.shortcutsEmpty,
              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        ],
      );
    }

    return ListView.builder(
      itemCount: realm.realms.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final element = realm.realms[index];

        return InkWell(
          child: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.supervised_user_circle, color: Colors.white),
                  ),
                ),
                Text(element.name, textAlign: TextAlign.center),
              ],
            ),
          ),
          onTap: () async {
            if (SolianTheme.isLargeScreen(context)) {
              await realm.fetchSingle(auth, element.alias);
              SolianRouter.router.pushNamed('realms');
            } else {
              SolianRouter.router.pushNamed(
                'realms.details',
                pathParameters: {'realm': element.alias},
              );
            }
          },
        );
      },
    );
  }
}
