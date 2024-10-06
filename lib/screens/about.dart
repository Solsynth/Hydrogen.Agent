import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const denseButtonStyle =
        ButtonStyle(visualDensity: VisualDensity(vertical: -4));

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Image.asset('assets/logo.png', width: 120, height: 120),
          ),
          const Gap(8),
          Text(
            'Solian',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text(
            'The Solar Network',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(8),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              return Text(
                'v${snapshot.data!.version} · ${snapshot.data!.buildNumber}',
                style: const TextStyle(fontFamily: 'monospace'),
              );
            },
          ),
          Text('Copyright © ${DateTime.now().year} Solsynth LLC'),
          const Gap(16),
          CenteredContainer(
            maxWidth: 280,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  style: denseButtonStyle,
                  child: Text('appDetails'.tr),
                  onPressed: () async {
                    final info = await PackageInfo.fromPlatform();

                    showAboutDialog(
                      context: context,
                      applicationVersion:
                          '${info.version} (${info.buildNumber})',
                      applicationLegalese:
                          'The Solar Network App is an intuitive and open-source social network and computing platform. Experience the freedom of a user-friendly design that empowers you to create and connect with communities on your own terms. Embrace the future of social networking with a platform that prioritizes your independence and privacy.',
                      applicationIcon: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        child: Image.asset('assets/logo.png',
                            width: 60, height: 60),
                      ),
                    );
                  },
                ),
                TextButton(
                  style: denseButtonStyle,
                  child: Text('projectWebsite'.tr),
                  onPressed: () {
                    launchUrlString(
                        'https://solsynth.dev/products/solar-network');
                  },
                ),
                TextButton(
                  style: denseButtonStyle,
                  child: Text('termRelated'.tr),
                  onPressed: () {
                    launchUrlString('https://solsynth.dev/terms');
                  },
                ),
                TextButton(
                  style: denseButtonStyle,
                  child: Text('serviceStatus'.tr),
                  onPressed: () {
                    launchUrlString('https://status.solsynth.dev');
                  },
                ),
              ],
            ),
          ),
          const Gap(16),
          const Text(
            'Open-sourced under AGPLv3',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 12,
            ),
          ),
          FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              const textStyle = TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 12,
              );
              if (!snapshot.hasData ||
                  !snapshot.data!.containsKey('first_boot_time')) {
                return Text(
                  'firstBootTime'.trParams({'time': 'unknown'.tr}),
                  style: textStyle,
                );
              } else {
                return Text(
                  'firstBootTime'.trParams({
                    'time': DateFormat('yyyy-MM-dd').format(
                      DateTime.tryParse(
                            snapshot.data!.getString('first_boot_time')!,
                          )?.toLocal() ??
                          DateTime.now(),
                    ),
                  }),
                  style: textStyle,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
