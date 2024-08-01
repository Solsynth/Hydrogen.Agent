import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const denseButtonStyle =
        ButtonStyle(visualDensity: VisualDensity(vertical: -4));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 64, height: 64)
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1000.ms),
            Text(
              'Solian',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              'The Solar Network',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                return Text(
                  'v${snapshot.data!.version} · ${snapshot.data!.buildNumber}',
                  style: const TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
            Text('Copyright © ${DateTime.now().year} Solsynth LLC'),
            const SizedBox(height: 16),
            TextButton(
              style: denseButtonStyle,
              child: const Text('App Details'),
              onPressed: () async {
                final info = await PackageInfo.fromPlatform();

                showAboutDialog(
                  context: context,
                  applicationVersion: '${info.version} (${info.buildNumber})',
                  applicationLegalese:
                      'The Solar Network App is an intuitive and self-hostable social network and computing platform. Experience the freedom of a user-friendly design that empowers you to create and connect with communities on your own terms. Embrace the future of social networking with a platform that prioritizes your independence and privacy.',
                  applicationIcon: Image.asset(
                    'assets/logo.png',
                    width: 56,
                    height: 56,
                  ),
                );
              },
            ),
            TextButton(
              style: denseButtonStyle,
              child: const Text('Project Website'),
              onPressed: () {
                launchUrlString('https://solsynth.dev/products/solar-network');
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Open-sourced under AGPLv3',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
