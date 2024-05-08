import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/chat/channel_action.dart';
import 'package:solian/widgets/chat/message.dart';
import 'package:solian/widgets/chat/message_action.dart';
import 'package:solian/widgets/chat/message_editor.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatelessWidget {
  final String alias;
  final String realm;

  const ChatScreen({super.key, required this.alias, this.realm = 'global'});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    return IndentScaffold(
      title: chat.focusChannel?.name ?? 'Loading...',
      hideDrawer: true,
      showSafeArea: true,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      appBarActions: chat.focusChannel != null
          ? [
              ChannelCallAction(
                call: chat.ongoingCall,
                channel: chat.focusChannel!,
                realm: realm,
                onUpdate: () => chat.fetchChannel(context, auth, chat.focusChannel!.alias, realm),
              ),
              ChannelManageAction(
                channel: chat.focusChannel!,
                realm: realm,
                onUpdate: () => chat.fetchChannel(context, auth, chat.focusChannel!.alias, realm),
              ),
            ]
          : [],
      body: ChatWidget(
        alias: alias,
        realm: realm,
      ),
    );
  }
}

class ChatWidget extends StatefulWidget {
  final String alias;
  final String realm;

  const ChatWidget({super.key, required this.alias, required this.realm});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  bool _isReady = false;

  late final ChatProvider _chat;

  Future<void> joinChannel() async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    var uri = getRequestUri(
      'messaging',
      '/api/channels/${widget.realm}/${widget.alias}/members/me',
    );

    var res = await auth.client!.post(uri);
    if (res.statusCode == 200) {
      setState(() {});
      _chat.historyPagingController?.refresh();
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message).then((_) {
        SolianRouter.router.pop();
      });
    }
  }

  bool getMessageMergeable(Message? a, Message? b) {
    if (a?.replyTo != null) return false;
    if (a == null || b == null) return false;
    if (a.senderId != b.senderId) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 3;
  }

  Message? _editingItem;
  Message? _replyingItem;

  void viewActions(Message item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ChatMessageAction(
        channel: widget.alias,
        realm: widget.realm,
        item: item,
        onEdit: () => setState(() {
          _editingItem = item;
        }),
        onReply: () => setState(() {
          _replyingItem = item;
        }),
      ),
    );
  }

  void showUnavailableDialog() {
    final content = widget.realm == 'global'
        ? AppLocalizations.of(context)!.chatChannelUnavailableCaption
        : AppLocalizations.of(context)!.chatChannelUnavailableCaptionWithRealm;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chatChannelUnavailable),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
              SolianRouter.router.pop();
            },
          ),
          ...(widget.realm != 'global'
              ? [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.join),
                    onPressed: () {
                      Navigator.of(context).pop();
                      joinChannel();
                    },
                  ),
                ]
              : [])
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      final auth = context.read<AuthProvider>();

      if (!_chat.isOpened) await _chat.connect(auth);

      _chat.fetchOngoingCall(widget.alias, widget.realm);
      _chat.fetchChannel(context, auth, widget.alias, widget.realm).then((result) {
        if (result.isAvailable == false) {
          showUnavailableDialog();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget chatHistoryBuilder(context, item, index) {
      bool isMerged = false, hasMerged = false;
      if (index > 0) {
        hasMerged = getMessageMergeable(_chat.historyPagingController?.itemList?[index - 1], item);
      }
      if (index + 1 < (_chat.historyPagingController?.itemList?.length ?? 0)) {
        isMerged = getMessageMergeable(item, _chat.historyPagingController?.itemList?[index + 1]);
      }
      return InkWell(
        child: Container(
          padding: EdgeInsets.only(
            top: !isMerged ? 8 : 0,
            bottom: !hasMerged ? 8 : 0,
            left: 12,
            right: 12,
          ),
          child: ChatMessage(
            item: item,
            underMerged: isMerged,
          ),
        ),
        onLongPress: () => viewActions(item),
      ).animate(key: Key('m${item.id}'), autoPlay: true).slideY(
            curve: Curves.fastEaseInToSlowEaseOut,
            duration: 350.ms,
            begin: 0.25,
            end: 0,
          );
    }

    if (!_isReady) {
      _isReady = true;
      _chat = context.watch<ChatProvider>();
    }

    final callBanner = MaterialBanner(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 20),
      leading: const Icon(Icons.call_received),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      dividerColor: const Color.fromARGB(1, 0, 0, 0),
      content: Text(AppLocalizations.of(context)!.chatCallOngoing),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.chatCallJoin),
          onPressed: () {
            SolianRouter.router.pushNamed(
              'chat.channel.call',
              extra: _chat.ongoingCall,
              pathParameters: {'channel': widget.alias},
            );
          },
        ),
      ],
    );

    if (_chat.focusChannel == null || _chat.historyPagingController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: PagedListView<int, Message>(
                reverse: true,
                pagingController: _chat.historyPagingController!,
                builderDelegate: PagedChildBuilderDelegate<Message>(
                  animateTransitions: true,
                  transitionDuration: 350.ms,
                  itemBuilder: chatHistoryBuilder,
                  noItemsFoundIndicatorBuilder: (_) => Container(),
                ),
              ),
            ),
            ChatMessageEditor(
              realm: widget.realm,
              channel: widget.alias,
              editing: _editingItem,
              replying: _replyingItem,
              onReset: () => setState(() {
                _editingItem = null;
                _replyingItem = null;
              }),
            ),
          ],
        ),
        _chat.ongoingCall != null ? callBanner.animate().slideY() : Container(),
      ],
    );
  }
}
