import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:solian/exts.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/providers/theme_switcher.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/sized_container.dart';

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

  late final List<({String label, Future<void> Function() action})> _periods = [
    (
      label: 'bsLoadingTheme',
      action: () async {
        await context.read<ThemeSwitcher>().restoreTheme();
      },
    ),
    (
      label: 'bsCheckForUpdate',
      action: () async {
        if (PlatformInfo.isWeb) return;
        try {
          final info = await PackageInfo.fromPlatform();
          final localVersionString = '${info.version}+${info.buildNumber}';
          final resp = await GetConnect().get(
            'https://git.solsynth.dev/api/v1/repos/hydrogen/solian/tags?limit=1',
          );
          if (resp.body[0]['name'] != localVersionString) {
            setState(() {
              _isErrored = true;
              _subtitle = PlatformInfo.isIOS || PlatformInfo.isMacOS
                  ? 'bsCheckForUpdateDescApple'.tr
                  : 'bsCheckForUpdateDescCommon'.tr;
            });
          }
        } catch (e) {
          setState(() {
            _isErrored = true;
            _subtitle = 'bsCheckForUpdateFailed'.tr;
          });
        }
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
              Get.find<ChannelProvider>().refreshAvailableChannel(),
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
            Get.find<WebSocketProvider>().registerPushNotifications();
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
    }
  }

  @override
  void initState() {
    super.initState();
    _runPeriods();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _isErrored) {
      return GestureDetector(
        child: Material(
          color: Theme.of(context).colorScheme.surface,
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
