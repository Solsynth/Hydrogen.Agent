import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:solian/models/notification.dart' as model;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isSubmitting = false;

  Future<void> markAllRead() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    final nty = context.read<NotifyProvider>();
    List<int> markList = List.empty(growable: true);
    for (final element in nty.notifications) {
      if (element.isRealtime) continue;
      markList.add(element.id);
    }

    nty.clearRealtime();

    if(markList.isNotEmpty) {
      var uri = getRequestUri('passport', '/api/notifications/batch/read');
      await auth.client!.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': markList}),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.notifyMarkAllReadDone),
    ));

    await nty.fetch(auth);

    setState(() => _isSubmitting = false);
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      final nty = context.read<NotifyProvider>();
      nty.allRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nty = context.watch<NotifyProvider>();

    return IndentScaffold(
      noSafeArea: true,
      hideDrawer: true,
      title: AppLocalizations.of(context)!.notification,
      child: RefreshIndicator(
        onRefresh: () => nty.fetch(auth),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
            ),
            if (nty.notifications.isNotEmpty)
              SliverToBoxAdapter(
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.secondaryContainer,
                  leading: const Icon(Icons.checklist),
                  title: Text(AppLocalizations.of(context)!.notifyMarkAllRead),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                  onTap: _isSubmitting ? null : markAllRead,
                ),
              ),
            nty.notifications.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: ListTile(
                        leading: const Icon(Icons.check),
                        title: Text(AppLocalizations.of(context)!.notifyDone),
                        subtitle: Text(AppLocalizations.of(context)!.notifyDoneCaption),
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: nty.notifications.length,
                    itemBuilder: (BuildContext context, int index) {
                      var element = nty.notifications[index];
                      return NotificationItem(
                        index: index,
                        item: element,
                        onDismiss: () => nty.clearAt(index),
                      );
                    },
                  ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  AppLocalizations.of(context)!.notifyListHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final int index;
  final model.Notification item;
  final void Function()? onDismiss;

  const NotificationItem({super.key, required this.index, required this.item, this.onDismiss});

  bool get hasLinks => item.links != null && item.links!.isNotEmpty;

  void showLinks(BuildContext context) {
    if (!hasLinks) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 34, bottom: 12),
              child: Text(
                'Links',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: item.links!.length,
                itemBuilder: (BuildContext context, int index) {
                  var element = item.links![index];
                  return ListTile(
                    title: Text(element.label),
                    onTap: () async {
                      await launchUrlString(element.url);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> markAsRead(model.Notification element, BuildContext context) async {
    if (element.isRealtime) return;

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    var id = element.id;
    var uri = getRequestUri('passport', '/api/notifications/$id/read');
    await auth.client!.put(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('n${item.id}'),
      onDismissed: (direction) {
        markAsRead(item, context).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.subject} is marked as read')),
          );
        });
        if (onDismiss != null) {
          onDismiss!();
        }
      },
      background: Container(
        color: Colors.lightBlue,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        child: ListTile(
          title: Text(item.subject),
          subtitle: Text(item.content),
          trailing: hasLinks
              ? TextButton(
                  onPressed: () => showLinks(context),
                  style: TextButton.styleFrom(shape: const CircleBorder()),
                  child: const Icon(Icons.more_vert),
                )
              : null,
        ),
      ),
    );
  }
}
