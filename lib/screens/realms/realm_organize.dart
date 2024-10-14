import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:uuid/uuid.dart';

class RealmOrganizeArguments {
  final Realm? edit;

  RealmOrganizeArguments({this.edit});
}

class RealmOrganizeScreen extends StatefulWidget {
  final Realm? edit;

  const RealmOrganizeScreen({super.key, this.edit});

  @override
  State<RealmOrganizeScreen> createState() => _RealmOrganizeScreenState();
}

class _RealmOrganizeScreenState extends State<RealmOrganizeScreen> {
  bool _isBusy = false;

  final _aliasController = TextEditingController();
  final _avatarController = TextEditingController();
  final _bannerController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isCommunity = false;
  bool _isPublic = false;

  void _applyRealm() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    if (_aliasController.value.text.isEmpty) _randomizeAlias();

    setState(() => _isBusy = true);

    final client = await auth.configureClient('auth');

    final payload = {
      'alias': _aliasController.value.text.toLowerCase(),
      'name': _nameController.value.text,
      'description': _descriptionController.value.text,
      'avatar': _avatarController.value.text,
      'banner': _bannerController.value.text,
      'is_public': _isPublic,
      'is_community': _isCommunity,
    };

    Response resp;
    if (widget.edit != null) {
      resp = await client.put('/realms/${widget.edit!.id}', payload);
    } else {
      resp = await client.post('/realms', payload);
    }
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isBusy = false);
  }

  final _imagePicker = ImagePicker();

  Future<void> _editImage(String position) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    XFile file;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (PlatformInfo.canCropImage) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'cropImage'.tr,
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            aspectRatioPresets: [
              if (position == 'avatar') CropAspectRatioPreset.square,
              if (position == 'banner') _BannerCropAspectRatioPreset(),
            ],
          ),
          IOSUiSettings(
            title: 'cropImage'.tr,
            aspectRatioPresets: [
              if (position == 'avatar') CropAspectRatioPreset.square,
              if (position == 'banner') _BannerCropAspectRatioPreset(),
            ],
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile == null) return;
      file = XFile(croppedFile.path);
    } else {
      file = XFile(image.path);
    }

    setState(() => _isBusy = true);

    final AttachmentProvider attach = Get.find();

    Attachment? attachResult;
    try {
      attachResult = await attach.createAttachmentDirectly(
        await file.readAsBytes(),
        file.path,
        'avatar',
        null,
      );
    } catch (e) {
      setState(() => _isBusy = false);
      context.showErrorDialog(e);
      return;
    }

    switch (position) {
      case 'avatar':
        _avatarController.text = attachResult.rid;
        break;
      case 'banner':
        _bannerController.text = attachResult.rid;
        break;
    }

    setState(() => _isBusy = false);
  }

  void _randomizeAlias() {
    _aliasController.text =
        const Uuid().v4().replaceAll('-', '').substring(0, 12);
  }

  void _syncWidget() {
    if (widget.edit != null) {
      _aliasController.text = widget.edit!.alias;
      _nameController.text = widget.edit!.name;
      _descriptionController.text = widget.edit!.description;
      _avatarController.text = widget.edit!.avatar ?? '';
      _bannerController.text = widget.edit!.banner ?? '';
      _isPublic = widget.edit!.isPublic;
      _isCommunity = widget.edit!.isCommunity;
    }
  }

  void _cancelAction() {
    AppRouter.instance.pop();
  }

  @override
  void initState() {
    _syncWidget();
    super.initState();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _avatarController.dispose();
    _bannerController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('realmOrganizing'.tr),
          centerTitle: false,
          toolbarHeight: AppTheme.toolbarHeight(context),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => _applyRealm(),
              child: Text('apply'.tr.toUpperCase()),
            )
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              LoadingIndicator(isActive: _isBusy),
              if (widget.edit != null)
                MaterialBanner(
                  leading: const Icon(Icons.edit),
                  leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                  dividerColor: Colors.transparent,
                  content: Text(
                    'realmEditingNotify'
                        .trParams({'realm': '#${widget.edit!.alias}'}),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _cancelAction,
                      child: Text('cancel'.tr),
                    ),
                  ],
                ).paddingOnly(bottom: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _aliasController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'realmAlias'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                    ),
                    onPressed: () => _randomizeAlias(),
                    child: const Icon(Icons.refresh),
                  )
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 2),
              const Divider(thickness: 0.3),
              TextField(
                autocorrect: true,
                controller: _nameController,
                decoration: InputDecoration.collapsed(
                  hintText: 'realmName'.tr,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ).paddingSymmetric(horizontal: 16, vertical: 8),
              const Divider(thickness: 0.3),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _avatarController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'realmAvatar'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                    ),
                    onPressed: _isBusy ? null : () => _editImage('avatar'),
                    child: const Icon(Icons.upload),
                  )
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 2),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _bannerController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'realmBanner'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                    ),
                    onPressed: _isBusy ? null : () => _editImage('banner'),
                    child: const Icon(Icons.upload),
                  )
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 2),
              const Divider(thickness: 0.3),
              Expanded(
                child: TextField(
                  minLines: 5,
                  maxLines: null,
                  autocorrect: true,
                  keyboardType: TextInputType.multiline,
                  controller: _descriptionController,
                  decoration: InputDecoration.collapsed(
                    hintText: 'realmDescription'.tr,
                  ),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ).paddingSymmetric(horizontal: 16, vertical: 12),
              ),
              const Divider(thickness: 0.3),
              CheckboxListTile(
                title: Text('realmPublic'.tr),
                value: _isPublic,
                onChanged: (newValue) =>
                    setState(() => _isPublic = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Text('realmCommunity'.tr),
                value: _isCommunity,
                onChanged: (newValue) =>
                    setState(() => _isCommunity = newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCropAspectRatioPreset extends CropAspectRatioPresetData {
  @override
  (int, int)? get data => (16, 7);

  @override
  String get name => '16x7';
}
