import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solian/platform.dart';
import 'package:solian/theme.dart';

class RootContainer extends StatelessWidget {
  final Widget? child;

  const RootContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PlatformInfo.isWeb
          ? Future.value(null)
          : getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final path = '${snapshot.data!.path}/app_background_image';
          final file = File(path);
          if (file.existsSync()) {
            return Material(
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.darken,
                  color: Theme.of(context).colorScheme.surface,
                  image: DecorationImage(
                    opacity: 0.2,
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                ),
                child: child,
              ),
            );
          }
        }

        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );
  }
}

class ResponsiveRootContainer extends StatelessWidget {
  final Widget? child;

  const ResponsiveRootContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    if (AppTheme.isLargeScreen(context)) {
      return child ?? SizedBox.shrink();
    } else {
      return RootContainer(child: child);
    }
  }
}
