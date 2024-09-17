import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solian/platform.dart';
import 'package:solian/widgets/sized_container.dart';

class AutoCacheImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit? fit;
  final bool noProgressIndicator;
  final bool noErrorWidget;
  final bool isDense;

  const AutoCacheImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.noProgressIndicator = false,
    this.noErrorWidget = false,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.canCacheImage) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        progressIndicatorBuilder: noProgressIndicator
            ? null
            : (context, url, downloadProgress) => Center(
                  child: CircularProgressIndicator(
                    value: downloadProgress.progress,
                  ),
                ),
        errorWidget: noErrorWidget
            ? null
            : (context, url, error) {
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: CenteredContainer(
                    maxWidth: 280,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: isDense ? 24 : 32)
                            .animate(onPlay: (e) => e.repeat(reverse: true))
                            .fade(duration: 500.ms),
                        if (!isDense)
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                );
              },
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: noProgressIndicator
          ? null
          : (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
      errorBuilder: noErrorWidget
          ? null
          : (context, error, stackTrace) {
              return Material(
                color: Theme.of(context).colorScheme.surface,
                child: CenteredContainer(
                  maxWidth: 280,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: isDense ? 24 : 32)
                          .animate(onPlay: (e) => e.repeat(reverse: true))
                          .fade(duration: 500.ms),
                      if (!isDense)
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              );
            },
    );
  }

  static ImageProvider provider(String url) {
    if (PlatformInfo.canCacheImage) {
      return CachedNetworkImageProvider(url);
    }
    return NetworkImage(url);
  }
}
