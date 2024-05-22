import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  final _imagePicker = ImagePicker();

  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _birthdayController = TextEditingController();

  int? _avatar;
  int? _banner;
  DateTime? _birthday;

  bool _isBusy = false;

  void selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(DateTime.now().year - 200),
      lastDate: DateTime(DateTime.now().year + 200),
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
        _birthdayController.text =
            DateFormat('yyyy-MM-dd hh:mm').format(_birthday!);
      });
    }
  }

  void syncWidget() async {
    setState(() => _isBusy = true);

    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile(noCache: true);
    setState(() {
      _usernameController.text = prof.body['name'];
      _nicknameController.text = prof.body['nick'];
      _descriptionController.text = prof.body['description'];
      _firstNameController.text = prof.body['profile']['first_name'];
      _lastNameController.text = prof.body['profile']['last_name'];
      _avatar = prof.body['avatar'];
      _banner = prof.body['banner'];
      if (prof.body['profile']['birthday'] != null) {
        _birthday = DateTime.parse(prof.body['profile']['birthday']);
        _birthdayController.text =
            DateFormat('yyyy-MM-dd hh:mm').format(_birthday!);
      }

      _isBusy = false;
    });
  }

  Future<void> updateImage(String position) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isBusy = true);

    final AttachmentProvider provider = Get.find();

    late Response attachResp;
    try {
      final file = File(image.path);
      final hash = await calculateFileSha256(file);
      attachResp = await provider.createAttachment(
        file,
        hash,
        'p.$position',
        ratio: await calculateFileAspectRatio(file),
      );
    } catch (e) {
      setState(() => _isBusy = false);
      context.showErrorDialog(e);
    }

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.reqAuthenticator);

    final resp = await client.put(
      '/api/users/me/$position',
      {'attachment': attachResp.body['id']},
    );
    if (resp.statusCode == 200) {
      syncWidget();

      context.showSnackbar('accountPersonalizeApplied'.tr);
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () => syncWidget());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ListView(
          children: [
            if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
            const SizedBox(height: 24),
            Stack(
              children: [
                AccountAvatar(content: _avatar, radius: 40),
                Positioned(
                  bottom: 0,
                  left: 40,
                  child: FloatingActionButton.small(
                    heroTag: const Key('avatar-editor'),
                    onPressed: () => updateImage('avatar'),
                    child: const Icon(
                      Icons.camera,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: _banner != null
                          ? Image.network(
                              '${ServiceFinder.services['paperclip']}/api/attachments/$_banner',
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : Container(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: const Key('banner-editor'),
                    onPressed: () => updateImage('banner'),
                    child: const Icon(
                      Icons.camera_alt,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: TextField(
                    readOnly: true,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'username'.tr,
                      prefixText: '@',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'nickname'.tr,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'firstName'.tr,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'lastName'.tr,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'description'.tr,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthdayController,
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'birthday'.tr,
              ),
              onTap: () => selectBirthday(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: null,
                  child: Text('reset'.tr),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: Text('apply'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
