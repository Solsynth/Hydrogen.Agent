import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/keypair.dart';
import 'package:solian/providers/keypair.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KeypairScreen extends StatelessWidget {
  const KeypairScreen({super.key});

  Widget getIcon(KeypairProvider provider, Keypair item) {
    if (item.id == provider.activeKeyId) {
      return const Icon(Icons.check_box);
    } else if (item.isOwned) {
      return const Icon(Icons.check_box_outlined);
    } else {
      return const Icon(Icons.key);
    }
  }

  void importKeys(BuildContext context) async {
    final controller = TextEditingController();
    final input = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.import),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.keypairImportHint),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)!.keypairSecretCode,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.next),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (input == null || input.isEmpty) return;

    context.read<KeypairProvider>().importKeys(input);
  }

  void exportKeys(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context) => const KeypairExportWidget());
  }

  @override
  Widget build(BuildContext context) {
    final keypair = context.watch<KeypairProvider>();
    final keys = keypair.keys.values.toList();

    return IndentScaffold(
      title: AppLocalizations.of(context)!.keypair,
      hideDrawer: true,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.generating_tokens),
        onPressed: () {
          final result = keypair.generateAESKey();
          keypair.setActiveKey(result.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.keypairGenerated),
          ));
        },
      ),
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.upload),
          tooltip: AppLocalizations.of(context)!.import,
          onPressed: () => importKeys(context),
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: AppLocalizations.of(context)!.export,
          onPressed: () => exportKeys(context),
        ),
      ],
      body: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final element = keys[index];
          final randomId = DateTime.now().microsecondsSinceEpoch >> 10;
          return Dismissible(
            key: Key(randomId.toString()),
            background: Container(
              color: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: const Icon(Icons.check, color: Colors.white),
            ),
            direction: keypair.activeKeyId != element.id && element.isOwned
                ? DismissDirection.horizontal
                : DismissDirection.none,
            child: ListTile(
              leading: getIcon(keypair, element),
              title: Text('${element.algorithm.toUpperCase()} Key'),
              subtitle: Text(element.id.toUpperCase()),
            ),
            onDismissed: (_) {
              keypair.setActiveKey(element.id);
            },
          );
        },
      ),
    );
  }
}

class KeypairExportWidget extends StatelessWidget {
  const KeypairExportWidget({super.key});

  String getEncodedContent(BuildContext context) {
    final keypair = context.read<KeypairProvider>();
    return utf8.fuse(base64).encode(jsonEncode(
          keypair.keys.values.map((x) => x.toJson()).toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      child: SizedBox(
        width: double.infinity,
        height: 640,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.export,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
              child: Text(
                AppLocalizations.of(context)!.keypairExportHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Markdown(
              selectable: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              data: '```\n${getEncodedContent(context)}\n```',
              padding: const EdgeInsets.all(0),
              styleSheet: MarkdownStyleSheet(
                codeblockPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
