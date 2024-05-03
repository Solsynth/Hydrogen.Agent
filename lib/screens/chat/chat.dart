import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/chat/channel_action.dart';
import 'package:solian/widgets/chat/chat_maintainer.dart';
import 'package:solian/widgets/chat/message.dart';
import 'package:solian/widgets/chat/message_action.dart';
import 'package:solian/widgets/chat/message_editor.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatelessWidget {
  final String alias;

  const ChatScreen({super.key, required this.alias});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return IndentScaffold(
      title: chat.focusChannel?.name ?? 'Loading...',
      hideDrawer: true,
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      appBarLeading: IconButton(icon: const Icon(Icons.tag), onPressed: () {}),
      appBarActions: chat.focusChannel != null
          ? [
              ChannelCallAction(
                call: chat.ongoingCall,
                channel: chat.focusChannel!,
                onUpdate: () => chat.fetchChannel(chat.focusChannel!.alias),
              ),
              ChannelManageAction(
                channel: chat.focusChannel!,
                onUpdate: () => chat.fetchChannel(chat.focusChannel!.alias),
              ),
            ]
          : [],
      child: ChatScreenWidget(
        alias: alias,
      ),
    );
  }
}

class ChatScreenWidget extends StatefulWidget {
  final String alias;

  const ChatScreenWidget({super.key, required this.alias});

  @override
  State<ChatScreenWidget> createState() => _ChatScreenWidgetState();
}

class _ChatScreenWidgetState extends State<ChatScreenWidget> {
  bool _isReady = false;

  final PagingController<int, Message> _pagingController = PagingController(firstPageKey: 0);

  late final ChatProvider _chat;

  Future<void> fetchMessages(int pageKey, BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final offset = pageKey;
    const take = 10;

    var uri = getRequestUri(
      'messaging',
      '/api/channels/${widget.alias}/messages?take=$take&offset=$offset',
    );

    var res = await auth.client!.get(uri);
    if (res.statusCode == 200) {
      final result = PaginationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      final items = result.data?.map((x) => Message.fromJson(x)).toList() ?? List.empty();
      final isLastPage = (result.count - pageKey) < take;
      if (isLastPage || result.data == null) {
        _pagingController.appendLastPage(items);
      } else {
        final nextPageKey = pageKey + items.length;
        _pagingController.appendPage(items, nextPageKey);
      }
    } else {
      _pagingController.error = utf8.decode(res.bodyBytes);
    }
  }

  bool getMessageMergeable(Message? a, Message? b) {
    if (a?.replyTo != null) return false;
    if (a == null || b == null) return false;
    if (a.senderId != b.senderId) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 5;
  }

  void addMessage(Message item) {
    setState(() {
      _pagingController.itemList?.insert(0, item);
    });
  }

  void updateMessage(Message item) {
    setState(() {
      _pagingController.itemList = _pagingController.itemList?.map((x) => x.id == item.id ? item : x).toList();
    });
  }

  void deleteMessage(Message item) {
    setState(() {
      _pagingController.itemList = _pagingController.itemList?.where((x) => x.id != item.id).toList();
    });
  }

  Message? _editingItem;
  Message? _replyingItem;

  void viewActions(Message item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ChatMessageAction(
        channel: widget.alias,
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

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) => fetchMessages(pageKey, context));

    super.initState();

    Future.delayed(Duration.zero, () {
      _chat.fetchOngoingCall(widget.alias);
      _chat.fetchChannel(widget.alias);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget chatHistoryBuilder(context, item, index) {
      bool isMerged = false, hasMerged = false;
      if (index > 0) {
        hasMerged = getMessageMergeable(_pagingController.itemList?[index - 1], item);
      }
      if (index + 1 < (_pagingController.itemList?.length ?? 0)) {
        isMerged = getMessageMergeable(item, _pagingController.itemList?[index + 1]);
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

    if (_chat.focusChannel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChatMaintainer(
      channel: _chat.focusChannel!,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PagedListView<int, Message>(
                  reverse: true,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                    animateTransitions: true,
                    transitionDuration: 350.ms,
                    itemBuilder: chatHistoryBuilder,
                    noItemsFoundIndicatorBuilder: (_) => Container(),
                  ),
                ),
              ),
              ChatMessageEditor(
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
      ),
      onInsertMessage: (message) => addMessage(message),
      onUpdateMessage: (message) => updateMessage(message),
      onDeleteMessage: (message) => deleteMessage(message),
      onCallStarted: (call) => _chat.setOngoingCall(call),
      onCallEnded: () => _chat.setOngoingCall(null),
    );
  }
}
