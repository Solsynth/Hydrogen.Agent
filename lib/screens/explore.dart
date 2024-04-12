import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/layout_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      context.read<LayoutConfig>().title = AppLocalizations.of(context)!.explore;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Woah"),
    );
  }
}
