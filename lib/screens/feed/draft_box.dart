import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/screens/feed.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/prev_page.dart';

class DraftBoxScreen extends StatelessWidget {
  const DraftBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle('draftBox'.tr),
          centerTitle: false,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          leading: const PrevPageButton(),
          actions: [
            FeedCreationButton(
              onCreated: () {},
            ),
            SizedBox(
              width: SolianTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
