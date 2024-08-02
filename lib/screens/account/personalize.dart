import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
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

  void _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday?.toLocal(),
      firstDate: DateTime(DateTime.now().year - 200),
      lastDate: DateTime(DateTime.now().year),
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = DateFormat('y/M/d').format(_birthday!);
      });
    }
  }

  void _syncWidget() async {
    _isBusy = true;

    final AuthProvider auth = Get.find();
    final prof = auth.userProfile.value!;
    _usernameController.text = prof['name'];
    _nicknameController.text = prof['nick'];
    _descriptionController.text = prof['description'];
    _firstNameController.text = prof['profile']['first_name'];
    _lastNameController.text = prof['profile']['last_name'];
    _avatar = prof['avatar'];
    _banner = prof['banner'];
    if (prof['profile']['birthday'] != null) {
      _birthday = DateTime.parse(prof['profile']['birthday']);
      _birthdayController.text =
          DateFormat('yyyy-MM-dd').format(_birthday!.toLocal());
    }

    _isBusy = false;
  }

  Future<void> _editImage(String position) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'cropImage'.tr,
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'cropImage'.tr,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile == null) return;
    final file = File(croppedFile.path);

    setState(() => _isBusy = true);

    final AttachmentProvider provider = Get.find();

    Attachment? attachResult;
    try {
      attachResult = await provider.createAttachment(
        await file.readAsBytes(),
        file.path,
        'p.$position',
        null,
      );
    } catch (e) {
      setState(() => _isBusy = false);
      context.showErrorDialog(e);
      return;
    }

    final client = auth.configureClient('auth');

    final resp = await client.put(
      '/users/me/$position',
      {'attachment': attachResult.id},
    );
    if (resp.statusCode == 200) {
      _syncWidget();
      context.showSnackbar('accountPersonalizeApplied'.tr);
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  void _editUserInfo() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final client = auth.configureClient('auth');

    _birthday?.toIso8601String();
    final resp = await client.put(
      '/users/me',
      {
        'nick': _nicknameController.value.text,
        'description': _descriptionController.value.text,
        'first_name': _firstNameController.value.text,
        'last_name': _lastNameController.value.text,
        'birthday': _birthday?.toUtc().toIso8601String(),
      },
    );
    if (resp.statusCode == 200) {
      _syncWidget();
      context.showSnackbar('accountPersonalizeApplied'.tr);
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    _syncWidget();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 32;

    return Material(
      color: Theme.of(context).colorScheme.surface,
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
                  onPressed: () => _editImage('avatar'),
                  child: const Icon(
                    Icons.camera,
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: padding),
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
                            ServiceFinder.buildUrl(
                                'files', '/attachments/$_banner'),
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
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
                  onPressed: () => _editImage('banner'),
                  child: const Icon(
                    Icons.camera_alt,
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: padding),
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
          ).paddingSymmetric(horizontal: padding),
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
          ).paddingSymmetric(horizontal: padding),
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
          ).paddingSymmetric(horizontal: padding),
          const SizedBox(height: 16),
          TextField(
            controller: _birthdayController,
            readOnly: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'birthday'.tr,
            ),
            onTap: () => _selectBirthday(),
          ).paddingSymmetric(horizontal: padding),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isBusy ? null : () => _syncWidget(),
                child: Text('reset'.tr),
              ),
              ElevatedButton(
                onPressed: _isBusy ? null : () => _editUserInfo(),
                child: Text('apply'.tr),
              ),
            ],
          ).paddingSymmetric(horizontal: padding),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _descriptionController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }
}
