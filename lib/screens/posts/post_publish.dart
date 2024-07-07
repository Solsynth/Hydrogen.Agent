import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/posts/tags_field.dart';
import 'package:solian/widgets/prev_page.dart';
import 'package:textfield_tags/textfield_tags.dart';

class PostPublishingArguments {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;

  PostPublishingArguments({this.edit, this.reply, this.repost, this.realm});
}

class PostPublishingScreen extends StatefulWidget {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;

  const PostPublishingScreen({
    super.key,
    this.edit,
    this.reply,
    this.repost,
    this.realm,
  });

  @override
  State<PostPublishingScreen> createState() => _PostPublishingScreenState();
}

class _PostPublishingScreenState extends State<PostPublishingScreen> {
  final _contentController = TextEditingController();
  final _tagsController = StringTagController();

  bool _isBusy = false;

  List<int> _attachments = List.empty();

  void showAttachments() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPublishPopup(
        usage: 'i.attachment',
        current: _attachments,
        onUpdate: (value) => _attachments = value,
      ),
    );
  }

  void applyPost() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;
    if (_contentController.value.text.isEmpty) return;

    setState(() => _isBusy = true);

    final client = auth.configureClient('interactive');

    final payload = {
      'content': _contentController.value.text,
      'tags': _tagsController.getTags?.map((x) => {'alias': x}).toList() ??
          List.empty(),
      'attachments': _attachments,
      if (widget.edit != null) 'alias': widget.edit!.alias,
      if (widget.reply != null) 'reply_to': widget.reply!.id,
      if (widget.repost != null) 'repost_to': widget.repost!.id,
      if (widget.realm != null) 'realm': widget.realm!.alias,
    };

    Response resp;
    if (widget.edit != null) {
      resp = await client.put('/api/posts/${widget.edit!.id}', payload);
    } else {
      resp = await client.post('/api/posts', payload);
    }
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isBusy = false);
  }

  void syncWidget() {
    if (widget.edit != null) {
      _contentController.text = widget.edit!.content;
      _attachments = widget.edit!.attachments ?? List.empty();
    }
  }

  void cancelAction() {
    AppRouter.instance.pop();
  }

  @override
  void initState() {
    syncWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    final notifyBannerActions = [
      TextButton(
        onPressed: cancelAction,
        child: Text('cancel'.tr),
      )
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle('postPublishing'.tr),
          centerTitle: false,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          leading: const PrevPageButton(),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => applyPost(),
              child: Text('postAction'.tr.toUpperCase()),
            )
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              ListView(
                children: [
                  if (_isBusy)
                    const LinearProgressIndicator().animate().scaleX(),
                  if (widget.edit != null)
                    MaterialBanner(
                      leading: const Icon(Icons.edit),
                      leadingPadding:
                          const EdgeInsets.only(left: 10, right: 20),
                      dividerColor: Colors.transparent,
                      content: Text('postEditingNotify'.tr),
                      actions: notifyBannerActions,
                    ),
                  if (widget.reply != null)
                    ExpansionTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.reply,
                        size: 18,
                      ).paddingOnly(left: 2),
                      title: Text('postReplyingNotify'.trParams(
                        {'username': '@${widget.reply!.author.name}'},
                      )),
                      collapsedBackgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      children: [
                        PostItem(
                          item: widget.reply!,
                          isReactable: false,
                        ).paddingOnly(bottom: 8),
                      ],
                    ),
                  if (widget.repost != null)
                    ExpansionTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.retweet,
                        size: 18,
                      ).paddingOnly(left: 2),
                      title: Text('postRepostingNotify'.trParams(
                        {'username': '@${widget.repost!.author.name}'},
                      )),
                      collapsedBackgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      children: [
                        PostItem(
                          item: widget.repost!,
                          isReactable: false,
                        ).paddingOnly(bottom: 8),
                      ],
                    ),
                  FutureBuilder(
                    future: auth.getProfile(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListTile(
                          leading: AccountAvatar(
                              content: snapshot.data?.body!['avatar'],
                              radius: 22),
                          title: Text(snapshot.data?.body!['nick']),
                          subtitle: Text('postIdentityNotify'.tr),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                  if (widget.realm != null)
                    MaterialBanner(
                      leading: const Icon(Icons.group),
                      leadingPadding:
                          const EdgeInsets.only(left: 10, right: 20),
                      dividerColor: Colors.transparent,
                      content: Text(
                        'postInRealmNotify'
                            .trParams({'realm': '#${widget.realm!.alias}'}),
                      ),
                      actions: notifyBannerActions,
                    ),
                  const Divider(thickness: 0.3, height: 0.3)
                      .paddingOnly(bottom: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      maxLines: null,
                      autofocus: true,
                      autocorrect: true,
                      keyboardType: TextInputType.multiline,
                      controller: _contentController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'postContentPlaceholder'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    TagsField(
                      initialTags:
                          widget.edit?.tags?.map((x) => x.alias).toList(),
                      tagsController: _tagsController,
                      hintText: 'postTagsPlaceholder'.tr,
                    ),
                    const Divider(thickness: 0.3, height: 0.3),
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              shape: const CircleBorder(),
                            ),
                            child: const Icon(Icons.camera_alt),
                            onPressed: () => showAttachments(),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
