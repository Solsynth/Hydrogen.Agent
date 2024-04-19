import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatNewAction extends StatelessWidget {
  const ChatNewAction({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.chatNew,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(AppLocalizations.of(context)!.chatNewCreate),
                ),
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: Text(AppLocalizations.of(context)!.chatNewJoin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
