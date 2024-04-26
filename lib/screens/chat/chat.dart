import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/chat/channel_action.dart';
import 'package:solian/widgets/chat/maintainer.dart';
import 'package:solian/widgets/chat/message.dart';
import 'package:solian/widgets/chat/message_action.dart';
import 'package:solian/widgets/chat/message_editor.dart';
import 'package:solian/widgets/indent_wrapper.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String alias;

  const ChatScreen({super.key, required this.alias});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Channel? _channelMeta;

  final PagingController<int, Message> _pagingController = PagingController(firstPageKey: 0);

  final http.Client _client = http.Client();

  Future<Channel> fetchMetadata() async {
    var uri = getRequestUri('messaging', '/api/channels/${widget.alias}');
    var res = await _client.get(uri);
    if (res.statusCode == 200) {
      final result = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() => _channelMeta = Channel.fromJson(result));
      return _channelMeta!;
    } else {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
      throw Exception(message);
    }
  }

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
    if (a?.replyTo != null || b?.replyTo != null) return false;
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
    Future.delayed(Duration.zero, () {
      fetchMetadata();
    });

    _pagingController.addPageRequestListener((pageKey) => fetchMessages(pageKey, context));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
      hideDrawer: true,
      title: _channelMeta?.name ?? "Loading...",
      appBarActions: [
        _channelMeta != null ? ChannelAction(channel: _channelMeta!, onUpdate: () => fetchMetadata()) : Container(),
      ],
      child: FutureBuilder(
        future: fetchMetadata(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ChatMaintainer(
            channel: snapshot.data!,
            child: Column(
              children: [
                Expanded(
                  child: PagedListView<int, Message>(
                    reverse: true,
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<Message>(
                      noItemsFoundIndicatorBuilder: (_) => Container(),
                      itemBuilder: (context, item, index) {
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
                              key: Key('m${item.id}'),
                              item: item,
                              underMerged: isMerged,
                            ),
                          ),
                          onLongPress: () => viewActions(item),
                        );
                      },
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
            onInsertMessage: (message) => addMessage(message),
            onUpdateMessage: (message) => updateMessage(message),
            onDeleteMessage: (message) => deleteMessage(message),
          );
        },
      ),
    );
  }
}
