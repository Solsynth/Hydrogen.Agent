import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/reaction.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> doReact(
  String dataset,
  int id,
  String symbol,
  int attitude,
  final void Function(String symbol, int num) onReact,
  BuildContext context,
) async {
  final auth = context.read<AuthProvider>();
  if (!await auth.isAuthorized()) return;

  var uri = getRequestUri(
    'interactive',
    '/api/p/$dataset/$id/react',
  );

  var res = await auth.client!.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'symbol': symbol,
      'attitude': attitude,
    }),
  );

  if (res.statusCode == 201) {
    onReact(symbol, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.reactionAdded),
      ),
    );
  } else if (res.statusCode == 204) {
    onReact(symbol, -1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.reactionRemoved),
      ),
    );
  } else {
    final message = utf8.decode(res.bodyBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Something went wrong... $message")),
    );
  }

  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

class ReactionActionPopup extends StatefulWidget {
  final String dataset;
  final int id;
  final void Function(String symbol, int num) onReact;

  const ReactionActionPopup({
    super.key,
    required this.dataset,
    required this.id,
    required this.onReact,
  });

  @override
  State<ReactionActionPopup> createState() => _ReactionActionPopupState();
}

class _ReactionActionPopupState extends State<ReactionActionPopup> {
  bool _isSubmitting = false;

  Future<void> doWidgetReact(
    String symbol,
    int attitude,
    BuildContext context,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    await doReact(
      widget.dataset,
      widget.id,
      symbol,
      attitude,
      widget.onReact,
      context,
    );
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final reactEntries = reactions.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 20, bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            child: Text(
              AppLocalizations.of(context)!.reaction,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
        Expanded(
          child: ListView.builder(
            itemCount: reactions.length,
            itemBuilder: (BuildContext context, int index) {
              var info = reactEntries[index];
              return InkWell(
                onTap: () async {
                  await doWidgetReact(info.key, info.value.attitude, context);
                },
                child: ListTile(
                  title: Text(info.value.icon),
                  subtitle: Text(
                    ":${info.key}:",
                    style: const TextStyle(fontFamily: "monospace"),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
