import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/chat/chat_message_deletion.dart';

class ChatMessageAction extends StatefulWidget {
  final Channel channel;
  final Realm? realm;
  final Message item;
  final Function? onEdit;
  final Function? onReply;

  const ChatMessageAction({
    super.key,
    required this.channel,
    required this.realm,
    required this.item,
    this.onEdit,
    this.onReply,
  });

  @override
  State<ChatMessageAction> createState() => _ChatMessageActionState();
}

class _ChatMessageActionState extends State<ChatMessageAction> {
  bool _isBusy = false;
  bool _canModifyContent = false;

  void checkAbleToModifyContent() async {
    final AuthProvider provider = Get.find();
    if (!await provider.isAuthorized) return;

    setState(() => _isBusy = true);

    final prof = await provider.getProfile();
    setState(() {
      _canModifyContent =
          prof.body?['id'] == widget.item.sender.account.externalId;
      _isBusy = false;
    });
  }

  @override
  void initState() {
    super.initState();

    checkAbleToModifyContent();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'messageActionList'.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '#${widget.item.id.toString().padLeft(8, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const FaIcon(FontAwesomeIcons.reply, size: 20),
                  title: Text('reply'.tr),
                  onTap: () async {
                    if (widget.onReply != null) widget.onReply!();
                    Navigator.pop(context);
                  },
                ),
                if (_canModifyContent)
                  const Divider(thickness: 0.3, height: 0.3)
                      .paddingSymmetric(vertical: 16),
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.edit),
                    title: Text('edit'.tr),
                    onTap: () async {
                      if (widget.onEdit != null) widget.onEdit!();
                      Navigator.pop(context);
                    },
                  ),
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.delete),
                    title: Text('delete'.tr),
                    onTap: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => ChatMessageDeletionDialog(
                          channel: widget.channel,
                          realm: widget.realm,
                          item: widget.item,
                        ),
                      );
                      if (value != null) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
