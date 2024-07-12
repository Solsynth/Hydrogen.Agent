import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/feed/feed_tags_field.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:badges/badges.dart' as badges;

class ArticlePublishArguments {
  final Article? edit;
  final Realm? realm;

  ArticlePublishArguments({this.edit, this.realm});
}

class ArticlePublishScreen extends StatefulWidget {
  final Article? edit;
  final Realm? realm;

  const ArticlePublishScreen({
    super.key,
    this.edit,
    this.realm,
  });

  @override
  State<ArticlePublishScreen> createState() => _ArticlePublishScreenState();
}

class _ArticlePublishScreenState extends State<ArticlePublishScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = StringTagController();

  bool _isBusy = false;

  List<int> _attachments = List.empty();

  bool _isDraft = false;

  void showAttachments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AttachmentPublishPopup(
        usage: 'i.attachment',
        current: _attachments,
        onUpdate: (value) {
          setState(() => _attachments = value);
        },
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
      'title': _titleController.value.text,
      'description': _descriptionController.value.text,
      'content': _contentController.value.text,
      'tags': _tagsController.getTags?.map((x) => {'alias': x}).toList() ??
          List.empty(),
      'attachments': _attachments,
      'is_draft': _isDraft,
      if (widget.edit != null) 'alias': widget.edit!.alias,
      if (widget.realm != null) 'realm': widget.realm!.alias,
    };

    Response resp;
    if (widget.edit != null) {
      resp = await client.put('/api/articles/${widget.edit!.id}', payload);
    } else {
      resp = await client.post('/api/articles', payload);
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
      _titleController.text = widget.edit!.title;
      _descriptionController.text = widget.edit!.description;
      _contentController.text = widget.edit!.content;
      _attachments = widget.edit!.attachments ?? List.empty();
      _isDraft = widget.edit!.isDraft ?? false;
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
          leading: const AppBarLeadingButton(),
          title: AppBarTitle('articlePublish'.tr),
          centerTitle: false,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => applyPost(),
              child: Text(
                _isDraft
                    ? 'draftSave'.tr.toUpperCase()
                    : 'postAction'.tr.toUpperCase(),
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            ListView(
              children: [
                if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
                if (widget.edit != null)
                  MaterialBanner(
                    leading: const Icon(Icons.edit),
                    leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                    dividerColor: Colors.transparent,
                    content: Text('postEditingNotify'.tr),
                    actions: notifyBannerActions,
                  ),
                if (widget.realm != null)
                  MaterialBanner(
                    leading: const Icon(Icons.group),
                    leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                    dividerColor: Colors.transparent,
                    content: Text(
                      'postInRealmNotify'
                          .trParams({'realm': '#${widget.realm!.alias}'}),
                    ),
                    actions: notifyBannerActions,
                  ),
                const Divider(thickness: 0.3, height: 0.3)
                    .paddingOnly(bottom: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    maxLines: null,
                    autofocus: true,
                    autocorrect: true,
                    controller: _titleController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'articleTitlePlaceholder'.tr,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const Divider(thickness: 0.3, height: 0.3)
                    .paddingOnly(bottom: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    minLines: 1,
                    maxLines: 3,
                    autofocus: true,
                    autocorrect: true,
                    keyboardType: TextInputType.multiline,
                    controller: _descriptionController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'articleDescriptionPlaceholder'.tr,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const Divider(thickness: 0.3, height: 0.3)
                    .paddingSymmetric(vertical: 6),
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
                      hintText: 'articleContentPlaceholder'.tr,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
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
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          IconButton(
                            icon: _isDraft
                                ? const Icon(Icons.drive_file_rename_outline)
                                : const Icon(Icons.public),
                            color: _isDraft
                                ? Colors.grey.shade600
                                : Colors.green.shade700,
                            onPressed: () {
                              setState(() => _isDraft = !_isDraft);
                            },
                          ),
                          IconButton(
                            icon: badges.Badge(
                              badgeContent: Text(
                                _attachments.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              showBadge: _attachments.isNotEmpty,
                              position: badges.BadgePosition.topEnd(
                                top: -12,
                                end: -8,
                              ),
                              child: const Icon(Icons.camera_alt),
                            ),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () => showAttachments(),
                          ),
                        ],
                      ).paddingSymmetric(horizontal: 6, vertical: 8),
                    ),
                  ],
                ).paddingOnly(bottom: MediaQuery.of(context).padding.bottom),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
