import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solian/utils/platform.dart';

class AttachmentScreen extends StatelessWidget {
  final String url;
  final String? tag;

  const AttachmentScreen({super.key, this.tag, required this.url});

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(128),
        minScale: 0.1,
        maxScale: 16,
        panEnabled: true,
        scaleEnabled: true,
        child: PlatformInfo.canCacheImage ? CachedNetworkImage(imageUrl: url, fit: BoxFit.contain) : Image.network(url),
      ),
    );

    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: tag != null ? Hero(tag: tag!, child: image) : image,
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
