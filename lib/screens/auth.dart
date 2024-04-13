import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthorizationScreen extends StatelessWidget {
  final Uri authorizationUrl;

  const AuthorizationScreen(this.authorizationUrl, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.signIn),
      ),
      body: Stack(children: [
        WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.white)
            ..setNavigationDelegate(NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('solian')) {
                  Navigator.of(context).pop(request.url);
                  WebViewCookieManager().clearCookies();
                  return NavigationDecision.prevent;
                } else if (request.url.contains("sign-up")) {
                  launchUrl(Uri.parse(request.url));
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ))
            ..loadRequest(authorizationUrl)
            ..clearCache(),
        ),
      ]),
    );
  }
}
