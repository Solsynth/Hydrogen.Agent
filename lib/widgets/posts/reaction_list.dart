import 'package:flutter/material.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/reaction.dart';
import 'package:solian/widgets/posts/reaction_action.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReactionList extends StatefulWidget {
  final Post item;
  final Map<String, dynamic>? reactionList;
  final void Function(String symbol, int num) onReact;

  const ReactionList({
    super.key,
    required this.item,
    this.reactionList,
    required this.onReact,
  });

  @override
  State<ReactionList> createState() => _ReactionListState();
}

class _ReactionListState extends State<ReactionList> {
  bool _isSubmitting = false;

  void viewReactMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionActionPopup(
        dataset: '${widget.item.modelType}s',
        id: widget.item.id,
        onReact: widget.onReact,
      ),
    );
  }

  Future<void> doWidgetReact(
    String symbol,
    int attitude,
    BuildContext context,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    await doReact(
      '${widget.item.modelType}s',
      widget.item.id,
      symbol,
      attitude,
      widget.onReact,
      context,
    );
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: -4, vertical: -2);

    final reactEntries = widget.reactionList?.entries ?? List.empty();

    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      children: [
        ...reactEntries.map((x) {
          final info = reactions[x.key];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Text(info!.icon),
              label: Text(x.value.toString()),
              tooltip: ':${x.key}:',
              visualDensity: density,
              onPressed: _isSubmitting
                  ? null
                  : () => doWidgetReact(x.key, info.attitude, context),
            ),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_reaction, color: Colors.teal),
          label: Text(AppLocalizations.of(context)!.reactVerb),
          visualDensity: density,
          onPressed: () => viewReactMenu(context),
        ),
      ],
    );
  }
}
