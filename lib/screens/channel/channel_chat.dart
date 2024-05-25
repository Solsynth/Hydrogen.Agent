import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/services.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/chat/chat_message.dart';

class ChannelChatScreen extends StatefulWidget {
  final String alias;
  final String realm;

  const ChannelChatScreen({
    super.key,
    required this.alias,
    this.realm = 'global',
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  bool _isBusy = false;

  Channel? _channel;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 0);

  getChannel() async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    try {
      final resp = await provider.getChannel(widget.alias, realm: widget.realm);
      setState(() => _channel = Channel.fromJson(resp.body));
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  Future<void> getMessages(int pageKey) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.get(
        '/api/channels/${widget.realm}/${widget.alias}/messages?take=10&offset=$pageKey');

    if (resp.statusCode == 200) {
      final PaginationResult result = PaginationResult.fromJson(resp.body);
      final parsed = result.data?.map((e) => Message.fromJson(e)).toList();

      if (parsed != null && parsed.length >= 10) {
        _pagingController.appendPage(parsed, pageKey + parsed.length);
      } else if (parsed != null) {
        _pagingController.appendLastPage(parsed);
      }
    } else if (resp.statusCode == 403) {
      _pagingController.appendLastPage([]);
    } else {
      _pagingController.error = resp.bodyString;
    }
  }

  bool checkMessageMergeable(Message? a, Message? b) {
    if (a?.replyTo != null) return false;
    if (a == null || b == null) return false;
    if (a.senderId != b.senderId) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 3;
  }

  Widget chatHistoryBuilder(context, item, index) {
    bool isMerged = false, hasMerged = false;
    if (index > 0) {
      hasMerged = checkMessageMergeable(
        _pagingController.itemList?[index - 1],
        item,
      );
    }
    if (index + 1 < (_pagingController.itemList?.length ?? 0)) {
      isMerged = checkMessageMergeable(
        item,
        _pagingController.itemList?[index + 1],
      );
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
          isCompact: isMerged,
        ),
      ),
      onLongPress: () {},
    ).animate(key: Key('m${item.id}'), autoPlay: true).slideY(
          curve: Curves.fastEaseInToSlowEaseOut,
          duration: 350.ms,
          begin: 0.25,
          end: 0,
        );
  }

  @override
  void initState() {
    super.initState();

    getChannel().then((_) {
      _pagingController.addPageRequestListener(getMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_channel?.name ?? 'loading'.tr),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          SizedBox(
            width: SolianTheme.isLargeScreen(context) ? 8 : 16,
          ),
        ],
      ),
      body: Column(
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
        ],
      ),
    );
  }
}
