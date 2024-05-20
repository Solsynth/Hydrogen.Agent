import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/shells/nav_shell.dart' as shell;
import 'package:solian/widgets/attachments/attachment_publish.dart';

class PostPublishingScreen extends StatefulWidget {
  const PostPublishingScreen({super.key});

  @override
  State<PostPublishingScreen> createState() => _PostPublishingScreenState();
}

class _PostPublishingScreenState extends State<PostPublishingScreen> {
  final _contentController = TextEditingController();

  bool _isSubmitting = false;

  List<int> _attachments = List.empty();

  void showAttachments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPublishingPopup(
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

    setState(() => _isSubmitting = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['interactive'];
    client.httpClient.addAuthenticator(auth.reqAuthenticator);

    final resp = await client.post('/api/posts', {
      'content': _contentController.value.text,
      'attachments': _attachments,
    });
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.background,
      child: Scaffold(
        appBar: AppBar(
          title: Text('postPublishing'.tr),
          leading: const shell.BackButton(),
          actions: [
            TextButton(
              child: Text('postAction'.tr.toUpperCase()),
              onPressed: () => applyPost(),
            )
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
              FutureBuilder(
                future: auth.getProfile(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListTile(
                      leading: AccountAvatar(content: snapshot.data?.body!['avatar'], radius: 22),
                      title: Text(snapshot.data?.body!['nick']),
                      subtitle: Text('postIdentityNotify'.tr),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              const Divider(thickness: 0.3),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    maxLines: null,
                    autofocus: true,
                    autocorrect: true,
                    keyboardType: TextInputType.multiline,
                    controller: _contentController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'postContentPlaceholder'.tr,
                    ),
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 0.3, color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: const Icon(Icons.camera_alt),
                      onPressed: () => showAttachments(context),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
