import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:path/path.dart' show extension;

class AttachmentFullScreen extends StatefulWidget {
  final String parentId;
  final Attachment item;

  const AttachmentFullScreen(
      {super.key, required this.parentId, required this.item});

  @override
  State<AttachmentFullScreen> createState() => _AttachmentFullScreenState();
}

class _AttachmentFullScreenState extends State<AttachmentFullScreen> {
  bool _showDetails = true;

  bool _isDownloading = false;
  bool _isCompletedDownload = false;
  double? _progressOfDownload = 0;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = [
      'Bytes',
      'KiB',
      'MiB',
      'GiB',
      'TiB',
      'PiB',
      'EiB',
      'ZiB',
      'YiB'
    ];
    final i = (math.log(bytes) / math.log(k)).floor().toInt();
    return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
  }

  double _getRatio() {
    final value = widget.item.metadata?['ratio'];
    if (value == null) return 1;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 1;
  }

  Future<void> _saveToAlbum() async {
    final url = ServiceFinder.buildUrl(
      'files',
      '/attachments/${widget.item.id}',
    );

    if (PlatformInfo.isWeb) {
      await launchUrlString(url);
      return;
    }

    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) return;
    }

    setState(() => _isDownloading = true);

    var extName = extension(widget.item.name);
    if (extName.isEmpty) extName = '.png';
    final imagePath =
        '${Directory.systemTemp.path}/${widget.item.uuid}$extName';
    await Dio().download(
      url,
      imagePath,
      onReceiveProgress: (count, total) {
        setState(() => _progressOfDownload = count / total);
      },
    );

    bool isSuccess = false;
    try {
      await Gal.putImage(imagePath);
      isSuccess = true;
    } on GalException catch (e) {
      context.showErrorDialog(e.type.message);
    }

    context.showSnackbar(
      'attachmentSaved'.tr,
      action: SnackBarAction(
        label: 'openInAlbum'.tr,
        onPressed: () async => Gal.open(),
      ),
    );
    setState(() {
      _isDownloading = false;
      _isCompletedDownload = isSuccess;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final metaTextStyle = TextStyle(
      fontSize: 12,
      color: _unFocusColor,
    );

    return DismissiblePage(
      key: Key('attachment-dismissible${widget.item.id}'),
      direction: DismissiblePageDismissDirection.vertical,
      onDismissed: () => Navigator.pop(context),
      dismissThresholds: const {
        DismissiblePageDismissDirection.vertical: 0.0,
      },
      onDragStart: () {
        setState(() => _showDetails = false);
      },
      onDragEnd: () {
        setState(() => _showDetails = true);
      },
      child: GestureDetector(
        child: Stack(
          fit: StackFit.loose,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.zero,
                minScale: 1,
                maxScale: 16,
                panEnabled: true,
                scaleEnabled: true,
                child: AttachmentItem(
                  parentId: widget.parentId,
                  showHideButton: false,
                  item: widget.item,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate(target: _showDetails ? 1 : 0)
                .fadeIn(curve: Curves.fastEaseInToSlowEaseOut),
            Positioned(
              bottom: math.max(MediaQuery.of(context).padding.bottom, 16),
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.item.account != null)
                      Row(
                        children: [
                          IgnorePointer(
                            child: AccountAvatar(
                              content: widget.item.account!.avatar,
                              radius: 19,
                            ),
                          ),
                          const IgnorePointer(child: SizedBox(width: 8)),
                          Expanded(
                            child: IgnorePointer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'attachmentUploadBy'.tr,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    widget.item.account!.nick,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -2,
                            ),
                            icon: !_isDownloading
                                ? !_isCompletedDownload
                                    ? const Icon(Icons.save_alt)
                                    : const Icon(Icons.download_done)
                                : SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      value: _progressOfDownload,
                                      strokeWidth: 3,
                                    ),
                                  ),
                            onPressed:
                                _isDownloading ? null : () => _saveToAlbum(),
                          ),
                        ],
                      ),
                    const IgnorePointer(child: SizedBox(height: 4)),
                    IgnorePointer(
                      child: Text(
                        widget.item.alt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const IgnorePointer(child: SizedBox(height: 2)),
                    IgnorePointer(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          Text(
                            '#${widget.item.id}',
                            style: metaTextStyle,
                          ),
                          if (widget.item.metadata?['width'] != null &&
                              widget.item.metadata?['height'] != null)
                            Text(
                              '${widget.item.metadata?['width']}x${widget.item.metadata?['height']}',
                              style: metaTextStyle,
                            ),
                          if (widget.item.metadata?['ratio'] != null)
                            Text(
                              '${_getRatio().toPrecision(2)}',
                              style: metaTextStyle,
                            ),
                          Text(
                            _formatBytes(widget.item.size),
                            style: metaTextStyle,
                          ),
                          Text(
                            widget.item.mimetype,
                            style: metaTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(target: _showDetails ? 1 : 0)
                .fadeIn(curve: Curves.fastEaseInToSlowEaseOut),
          ],
        ),
        onTap: () {
          setState(() => _showDetails = !_showDetails);
        },
      ),
    );
  }
}
