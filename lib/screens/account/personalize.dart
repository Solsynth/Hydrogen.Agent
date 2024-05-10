import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: AppLocalizations.of(context)!.personalize,
      hideDrawer: true,
      body: const PersonalizeScreenWidget(),
    );
  }
}

class PersonalizeScreenWidget extends StatefulWidget {
  const PersonalizeScreenWidget({super.key});

  @override
  State<PersonalizeScreenWidget> createState() => _PersonalizeScreenWidgetState();
}

class _PersonalizeScreenWidgetState extends State<PersonalizeScreenWidget> {
  final _imagePicker = ImagePicker();

  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _birthdayController = TextEditingController();

  String? _avatar;
  String? _banner;
  DateTime? _birthday;

  bool _isSubmitting = false;

  void editBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(DateTime.now().year - 200),
      lastDate: DateTime(DateTime.now().year + 200),
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = DateFormat('yyyy-MM-dd hh:mm').format(_birthday!);
      });
    }
  }

  void resetInputs() async {
    final auth = context.read<AuthProvider>();
    final prof = await auth.getProfiles();
    setState(() {
      _usernameController.text = prof['name'];
      _nicknameController.text = prof['nick'];
      _descriptionController.text = prof['description'];
      _firstNameController.text = prof['profile']['first_name'];
      _lastNameController.text = prof['profile']['last_name'];
      if (prof['avatar'] != null && prof['avatar'].isNotEmpty) {
        _avatar = getRequestUri('passport', '/api/avatar/${prof['avatar']}').toString();
      }
      if (prof['banner'] != null && prof['banner'].isNotEmpty) {
        _banner = getRequestUri('passport', '/api/avatar/${prof['banner']}').toString();
      }
      if (prof['profile']['birthday'] != null) {
        _birthday = DateTime.parse(prof['profile']['birthday']);
        _birthdayController.text = DateFormat('yyyy-MM-dd hh:mm').format(_birthday!);
      }
    });
  }

  void applyChanges() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    final res = await auth.client!.put(
      getRequestUri('passport', '/api/users/me'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nick': _nicknameController.value.text,
        'description': _descriptionController.value.text,
        'first_name': _firstNameController.value.text,
        'last_name': _lastNameController.value.text,
        'birthday': _birthday?.toIso8601String(),
      }),
    );
    if (res.statusCode == 200) {
      await auth.fetchProfiles();
      resetInputs();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.personalizeApplied),
      ));
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> applyImage(String position) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isSubmitting = true);

    final file = File(image.path);
    try {
      final req = MultipartRequest('PUT', getRequestUri('passport', '/api/users/me/$position'));
      req.files.add(await MultipartFile.fromPath(position, file.path));

      var res = await auth.client!.send(req);
      if (res.statusCode == 200) {
        await auth.fetchProfiles();
        resetInputs();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.personalizeApplied),
        ));
      } else {
        throw Exception(utf8.decode(await res.stream.toBytes()));
      }
    } catch (err) {
      context.showErrorDialog(err);
    }

    setState(() => _isSubmitting = false);
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      resetInputs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ListView(
        children: [
          _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
          const SizedBox(height: 24),
          Stack(
            children: [
              AccountAvatar(source: _avatar ?? '', radius: 40, direct: true),
              Positioned(
                bottom: 0,
                left: 40,
                child: FloatingActionButton.small(
                  heroTag: const Key('avatar-editor'),
                  onPressed: () => applyImage('avatar'),
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: _banner != null
                        ? Image.network(
                            _banner!,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                  onPressed: () => applyImage('banner'),
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
                    labelText: AppLocalizations.of(context)!.username,
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
                    labelText: AppLocalizations.of(context)!.nickname,
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
                    labelText: AppLocalizations.of(context)!.firstName,
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
                    labelText: AppLocalizations.of(context)!.lastName,
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
              labelText: AppLocalizations.of(context)!.description,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _birthdayController,
            readOnly: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: AppLocalizations.of(context)!.birthday,
            ),
            onTap: editBirthday,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : () => resetInputs(),
                child: Text(AppLocalizations.of(context)!.reset),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => applyChanges(),
                child: Text(AppLocalizations.of(context)!.apply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
