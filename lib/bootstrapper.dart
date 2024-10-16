import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/notifications.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/providers/theme_switcher.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'package:version/version.dart';

class BootstrapperShell extends StatefulWidget {
  final Widget child;

  const BootstrapperShell({super.key, required this.child});

  @override
  State<BootstrapperShell> createState() => _BootstrapperShellState();
}

class _BootstrapperShellState extends State<BootstrapperShell> {
  bool _isBusy = true;
  bool _isErrored = false;
  bool _isDismissable = true;
  String? _subtitle;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  int _periodCursor = 0;

  final Completer _bootCompleter = Completer();

  void _requestRating() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('first_boot_time')) {
      final rawTime = prefs.getString('first_boot_time');
      final time = DateTime.tryParse(rawTime ?? '');
      if (time != null &&
          time.isBefore(DateTime.now().subtract(const Duration(days: 3)))) {
        final inAppReview = InAppReview.instance;
        if (prefs.getBool('rating_requested') == true) return;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
          prefs.setBool('rating_requested', true);
        } else {
          log('Unable request app review, unavailable');
        }
      }
    } else {
      prefs.setString('first_boot_time', DateTime.now().toIso8601String());
    }
  }

  void _updateNow(String localVersionString, String remoteVersionString) {
    context
        .showConfirmDialog(
      'updateAvailable'.tr,
      'updateAvailableDesc'.trParams({
        'from': localVersionString,
        'to': remoteVersionString,
      }),
    )
        .then((result) {
      if (result) {
        final model = UpdateModel(
          'https://files.solsynth.dev/d/production01/solian/app-arm64-v8a-release.apk',
          'solian-app-arm64-v8a-release.apk',
          'ic_launcher',
          'https://testflight.apple.com/join/YJ0lmN6O',
        );
        AzhonAppUpdate.update(model);
      }
    });
  }

  Future<void> _checkForUpdate() async {
    if (PlatformInfo.isWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      final localVersionString = '${info.version}+${info.buildNumber}';
      final resp = await GetConnect(
        timeout: const Duration(seconds: 60),
      ).get(
        'https://git.solsynth.dev/api/v1/repos/hydrogen/solian/tags?page=1&limit=1',
      );
      if (resp.statusCode != 200) {
        throw RequestException(resp);
      }
      final remoteVersionString =
          (resp.body as List).firstOrNull?['name'] ?? '0.0.0+0';
      final remoteVersion = Version.parse(remoteVersionString.split('+').first);
      final localVersion = Version.parse(localVersionString.split('+').first);
      final remoteBuildNumber =
          int.tryParse(remoteVersionString.split('+').last) ?? 0;
      final localBuildNumber =
          int.tryParse(localVersionString.split('+').last) ?? 0;
      final strictUpdate = prefs.getBool('check_update_strictly') ?? false;
      if (remoteVersion > localVersion ||
          (remoteVersion == localVersion &&
              remoteBuildNumber > localBuildNumber) ||
          (remoteVersionString != localVersionString && strictUpdate)) {
        if (PlatformInfo.isAndroid) {
          _updateNow(localVersionString, remoteVersionString);
        } else {
          context.showInfoDialog(
            'updateAvailable'.tr,
            'bsCheckForUpdateDesc'.tr,
          );
        }
      } else if (remoteVersionString != localVersionString) {
        _bootCompleter.future.then((_) {
          context.showSnackbar(
            'updateMayAvailable'.trParams({
              'version': remoteVersionString,
            }),
            action: PlatformInfo.isAndroid
                ? SnackBarAction(
                    label: 'updateNow'.tr,
                    onPressed: () {
                      _updateNow(localVersionString, remoteVersionString);
                    },
                  )
                : null,
          );
        });
      }
    } catch (e) {
      context.showErrorDialog('Unable to check update: $e');
    }
  }

  late final List<({String label, Future<void> Function() action})> _periods = [
    (
      label: 'bsLoadingTheme',
      action: () async {
        await context.read<ThemeSwitcher>().restoreTheme();
      },
    ),
    (
      label: 'bsCheckingServer',
      action: () async {
        final client = await ServiceFinder.configureClient('dealer');
        final resp = await client.get('/.well-known');
        if (resp.statusCode != null && resp.statusCode != 200) {
          setState(() {
            _isErrored = true;
            _subtitle = 'bsCheckingServerDown'.tr;
            _isDismissable = false;
          });
          throw Exception('unable connect to server');
        } else if (resp.statusCode == null) {
          setState(() {
            _isErrored = true;
            _subtitle = 'bsCheckingServerFail'.tr;
            _isDismissable = false;
          });
          throw Exception('unable connect to server');
        }
      },
    ),
    (
      label: 'bsAuthorizing',
      action: () async {
        final AuthProvider auth = Get.find();
        await auth.refreshAuthorizeStatus();
        if (auth.isAuthorized.isTrue) {
          await auth.refreshUserProfile();
        }
      },
    ),
    (
      label: 'bsEstablishingConn',
      action: () async {
        final AuthProvider auth = Get.find();
        if (auth.isAuthorized.isTrue) {
          await Get.find<WebSocketProvider>().connect();
        }
      },
    ),
    (
      label: 'bsPreparingData',
      action: () async {
        final AuthProvider auth = Get.find();
        try {
          await Future.wait([
            if (auth.isAuthorized.isTrue)
              Get.find<NotificationProvider>().fetchNotification(),
            if (auth.isAuthorized.isTrue)
              Get.find<RelationshipProvider>().refreshRelativeList(),
            if (auth.isAuthorized.isTrue)
              Get.find<RealmProvider>().refreshAvailableRealms(),
          ]);
        } catch (e) {
          context.showErrorDialog(e);
        }
      },
    ),
    (
      label: 'bsRegisteringPushNotify',
      action: () async {
        final AuthProvider auth = Get.find();
        if (auth.isAuthorized.isTrue) {
          try {
            Get.find<NotificationProvider>().registerPushNotifications();
          } catch (err) {
            context.showSnackbar(
              'pushNotifyRegisterFailed'.trParams({'reason': err.toString()}),
            );
          }
        }
      },
    ),
  ];

  Future<void> _runPeriods() async {
    try {
      for (var idx = 0; idx < _periods.length; idx++) {
        await _periods[idx].action();
        if (_isErrored && !_isDismissable) break;
        if (_periodCursor < _periods.length - 1) {
          setState(() => _periodCursor++);
        }
      }
    } finally {
      setState(() => _isBusy = false);
      Future.delayed(const Duration(milliseconds: 100), () {
        _bootCompleter.complete();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _runPeriods();
    _checkForUpdate();
    _bootCompleter.future.then((_) {
      _requestRating();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _isErrored) {
      return GestureDetector(
        child: RootContainer(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                height: 280,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child:
                        Image.asset('assets/logo.png', width: 80, height: 80),
                  ),
                ),
              ),
              Column(
                children: [
                  if (_isErrored && !_isDismissable && !_isBusy)
                    const Icon(Icons.cancel, size: 24),
                  if (_isErrored && _isDismissable && !_isBusy)
                    const Icon(Icons.warning, size: 24),
                  if ((_isErrored && _isDismissable && _isBusy) || _isBusy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  const Gap(12),
                  CenteredContainer(
                    maxWidth: 280,
                    child: Column(
                      children: [
                        if (_subtitle == null)
                          Text(
                            '${_periods[_periodCursor].label.tr} (${_periodCursor + 1}/${_periods.length})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _unFocusColor,
                            ),
                          ),
                        if (_subtitle != null)
                          Text(
                            _subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _unFocusColor,
                            ),
                          ).paddingOnly(bottom: 4),
                        if (!_isBusy && _isErrored && _isDismissable)
                          Text(
                            'bsDismissibleErrorHint'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _unFocusColor,
                            ),
                          ).paddingOnly(bottom: 5),
                        Text(
                          '2024 © Solsynth LLC',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: _unFocusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () {
          if (_isBusy) return;
          if (_isDismissable) {
            setState(() {
              _isBusy = false;
              _isErrored = false;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _bootCompleter.complete();
            });
          } else {
            setState(() {
              _isBusy = true;
              _isErrored = false;
              _periodCursor = 0;
            });
            _runPeriods();
          }
        },
      );
    }

    return widget.child;
  }
}
