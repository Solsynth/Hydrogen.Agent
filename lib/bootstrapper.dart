import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/relation.dart';
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
  String? _subtitle;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  int _periodCursor = 0;

  late final List<({String label, Future<void> Function() action})> _periods = [
    (
      label: 'bsCheckingServer',
      action: () async {
        final client = ServiceFinder.configureClient('dealer');
        final resp = await client.get('/.well-known');
        if (resp.statusCode != null && resp.statusCode != 200) {
          setState(() {
            _isErrored = true;
            _subtitle = 'bsCheckingServerDown'.tr;
          });
          throw Exception('unable connect to server');
        } else if (resp.statusCode == null) {
          setState(() {
            _isErrored = true;
            _subtitle = 'bsCheckingServerFail'.tr;
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
        if (auth.isAuthorized.isTrue) {
          await Future.wait([
            Get.find<ChannelProvider>().refreshAvailableChannel(),
            Get.find<RelationshipProvider>().refreshFriendList(),
          ]);
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
        if (_isErrored) break;
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
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              height: 280,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset('assets/logo.png', width: 80, height: 80)
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 850.ms, curve: Curves.easeInOut),
              ),
            ),
            GestureDetector(
              child: Column(
                children: [
                  if (_isErrored)
                    const Icon(Icons.cancel, size: 24)
                  else
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  const SizedBox(height: 12),
                  CenteredContainer(
                    maxWidth: 280,
                    child: Column(
                      children: [
                        Text(
                          _subtitle ??
                              '${_periods[_periodCursor].label.tr} (${_periodCursor + 1}/${_periods.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: _unFocusColor,
                          ),
                        ),
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
              onTap: () {
                if (_isBusy) return;
                setState(() {
                  _isBusy = true;
                  _isErrored = false;
                  _periodCursor = 0;
                });
                _runPeriods();
              },
            )
          ],
        ),
      );
    }

    return widget.child;
  }
}
