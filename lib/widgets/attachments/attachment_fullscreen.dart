import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      '/attachments/${widget.item.rid}',
    );

    if (PlatformInfo.isWeb || PlatformInfo.isDesktop) {
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
    final metaTextStyle = GoogleFonts.roboto(
      fontSize: 12,
      color: _unFocusColor,
      height: 1,
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
                        Colors.transparent,
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
                            child: AttachedCircleAvatar(
                              content: widget.item.account!.avatar,
                              radius: 19,
                            ),
                          ),
                          const Gap(8),
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
                    const Gap(4),
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
                    const Gap(2),
                    IgnorePointer(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (widget.item.metadata?['exif'] == null)
                            Text(
                              '#${widget.item.rid}',
                              style: metaTextStyle,
                            ),
                          if (widget.item.metadata?['exif']?['Model'] != null)
                            Text(
                              'shotOn'.trParams({
                                'device': widget.item.metadata?['exif']
                                    ?['Model']
                              }),
                              style: metaTextStyle,
                            ).paddingOnly(right: 2),
                          if (widget.item.metadata?['exif']?['ShutterSpeed'] !=
                              null)
                            Text(
                              widget.item.metadata?['exif']?['ShutterSpeed'],
                              style: metaTextStyle,
                            ).paddingOnly(right: 2),
                          if (widget.item.metadata?['exif']?['ISO'] != null)
                            Text(
                              'ISO${widget.item.metadata?['exif']?['ISO']}',
                              style: metaTextStyle,
                            ).paddingOnly(right: 2),
                          if (widget.item.metadata?['exif']?['Aperture'] !=
                              null)
                            Text(
                              'f/${widget.item.metadata?['exif']?['Aperture']}',
                              style: metaTextStyle,
                            ).paddingOnly(right: 2),
                          if (widget.item.metadata?['exif']?['Megapixels'] !=
                                  null &&
                              widget.item.metadata?['exif']?['Model'] != null)
                            Text(
                              '${widget.item.metadata?['exif']?['Megapixels']}MP',
                              style: metaTextStyle,
                            )
                          else
                            Text(
                              widget.item.size.formatBytes(),
                              style: metaTextStyle,
                            ),
                          Text(
                            '${widget.item.metadata?['width']}x${widget.item.metadata?['height']}',
                            style: metaTextStyle,
                          ),
                          if (widget.item.metadata?['ratio'] != null)
                            Text(
                              (widget.item.metadata?['ratio'] as num)
                                  .toStringAsFixed(2),
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
