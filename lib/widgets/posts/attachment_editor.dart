import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/exts.dart';

class AttachmentEditor extends StatefulWidget {
  final String provider;
  final List<Attachment> current;
  final void Function(List<Attachment> data) onUpdate;

  const AttachmentEditor({
    super.key,
    required this.provider,
    required this.current,
    required this.onUpdate,
  });

  @override
  State<AttachmentEditor> createState() => _AttachmentEditorState();
}

class _AttachmentEditorState extends State<AttachmentEditor> {
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  List<Attachment> _attachments = List.empty(growable: true);

  void viewAttachMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditorMethodPopup(
        pickImage: () => pickImageToUpload(context, ImageSource.gallery),
        takeImage: () => pickImageToUpload(context, ImageSource.camera),
        pickVideo: () => pickVideoToUpload(context, ImageSource.gallery),
        takeVideo: () => pickVideoToUpload(context, ImageSource.camera),
      ),
    );
  }

  Future<void> pickImageToUpload(BuildContext context, ImageSource source) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isSubmitting = true);

    final file = File(image.path);
    final hashcode = await calculateSha256(file);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      await uploadAttachment(file, hashcode);
    } catch (err) {
      context.showErrorDialog(err);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> pickVideoToUpload(BuildContext context, ImageSource source) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final image = await _imagePicker.pickVideo(source: source);
    if (image == null) return;

    setState(() => _isSubmitting = true);

    final file = File(image.path);
    final hashcode = await calculateSha256(file);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      await uploadAttachment(file, hashcode);
    } catch (err) {
      context.showErrorDialog(err);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> uploadAttachment(File file, String hashcode) async {
    final auth = context.read<AuthProvider>();

    final req = MultipartRequest('POST', getRequestUri(widget.provider, '/api/attachments'));
    req.files.add(await MultipartFile.fromPath('attachment', file.path));
    req.fields['hashcode'] = hashcode;

    var res = await auth.client!.send(req);
    if (res.statusCode == 200) {
      var result = Attachment.fromJson(
        jsonDecode(utf8.decode(await res.stream.toBytes()))["info"],
      );
      setState(() => _attachments.add(result));
      widget.onUpdate(_attachments);
    } else {
      throw Exception(utf8.decode(await res.stream.toBytes()));
    }
  }

  Future<void> disposeAttachment(BuildContext context, Attachment item, int index) async {
    final auth = context.read<AuthProvider>();

    final req = MultipartRequest('DELETE', getRequestUri(widget.provider, '/api/attachments/${item.id}'));

    setState(() => _isSubmitting = true);
    var res = await auth.client!.send(req);
    if (res.statusCode == 200) {
      setState(() => _attachments.removeAt(index));
      widget.onUpdate(_attachments);
    } else {
      final err = utf8.decode(await res.stream.toBytes());
      context.showErrorDialog(err);
    }
    setState(() => _isSubmitting = false);
  }

  Future<String> calculateSha256(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String getFileName(Attachment item) {
    return item.filename.replaceAll(RegExp(r'\.[^/.]+$'), '');
  }

  String getFileType(Attachment item) {
    switch (item.type) {
      case 1:
        return 'Photo';
      case 2:
        return 'Video';
      case 3:
        return 'Audio';
      default:
        return 'Others';
    }
  }

  String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = ['Bytes', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
    final i = (math.log(bytes) / math.log(k)).floor().toInt();
    return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
  }

  @override
  void initState() {
    _attachments = widget.current;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 20, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Text(
                  AppLocalizations.of(context)!.attachment,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FutureBuilder(
                future: auth.isAuthorized(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return TextButton(
                      onPressed: _isSubmitting ? null : () => viewAttachMethods(context),
                      style: TextButton.styleFrom(shape: const CircleBorder()),
                      child: const Icon(Icons.add_circle),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
        ),
        _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
        Expanded(
          child: ListView.separated(
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              var element = _attachments[index];
              return Container(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getFileName(element),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            "${getFileType(element)} · ${formatBytes(element.filesize)}",
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: const CircleBorder(),
                        foregroundColor: Colors.red,
                      ),
                      child: const Icon(Icons.delete),
                      onPressed: () => disposeAttachment(context, element, index),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(thickness: 0.3),
          ),
        ),
      ],
    );
  }
}

class AttachmentEditorMethodPopup extends StatelessWidget {
  final Function pickImage;
  final Function takeImage;
  final Function pickVideo;
  final Function takeVideo;

  const AttachmentEditorMethodPopup({
    super.key,
    required this.pickImage,
    required this.takeImage,
    required this.pickVideo,
    required this.takeVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: Text(
              AppLocalizations.of(context)!.attachmentAdd,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: GridView.count(
              primary: false,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 4,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => pickImage(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate, color: Colors.indigo),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.pickPhoto),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => takeImage(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.indigo),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.takePhoto),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => pickVideo(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera, color: Colors.teal),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.pickVideo),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => takeVideo(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.video_call, color: Colors.teal),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.takeVideo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
