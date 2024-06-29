import 'package:flutter/material.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ListenerShell extends StatefulWidget {
  final Widget child;

  const ListenerShell({super.key, required this.child});

  @override
  State<ListenerShell> createState() => _ListenerShellState();
}

class _ListenerShellState extends State<ListenerShell> with ProtocolListener {
  @override
  void initState() {
    protocolHandler.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    protocolHandler.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onProtocolUrlReceived(String url) {
    final uri = url.replaceFirst('solink://', '');
    if (uri == 'auth?status=done') {
      closeInAppWebView();
    }
  }
}
