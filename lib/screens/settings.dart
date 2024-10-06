import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/theme_switcher.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/reports/abuse_report.dart';
import 'package:solian/widgets/root_container.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  SharedPreferences? _prefs;

  Widget _buildCaptionHeader(String title) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(title),
    );
  }

  Widget _buildThemeColorButton(String label, Color color) {
    return IconButton(
      icon: Icon(Icons.circle, color: color),
      tooltip: label,
      onPressed: () {
        context.read<ThemeSwitcher>().setTheme(
              AppTheme.build(
                Brightness.light,
                seedColor: color,
              ),
              AppTheme.build(
                Brightness.dark,
                seedColor: color,
              ),
            );
        _prefs?.setInt('global_theme_color', color.value);
        context.clearSnackbar();
        context.showSnackbar('themeColorApplied'.tr);
      },
    );
  }

  static final List<(String, Color)> _presentTheme = [
    ('themeColorRed', const Color.fromRGBO(154, 98, 91, 1)),
    ('themeColorBlue', const Color.fromRGBO(103, 96, 193, 1)),
    ('themeColorMiku', const Color.fromRGBO(56, 120, 126, 1)),
    ('themeColorKagamine', const Color.fromRGBO(244, 183, 63, 1)),
    ('themeColorLuka', const Color.fromRGBO(243, 174, 218, 1)),
  ];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((inst) {
      _prefs = inst;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: ListView(
        children: [
          _buildCaptionHeader('themeColor'.tr),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _presentTheme
                  .map((x) => _buildThemeColorButton(x.$1, x.$2))
                  .toList(),
            ).paddingSymmetric(horizontal: 12, vertical: 8),
          ),
          _buildCaptionHeader('notification'.tr),
          Tooltip(
            message: 'settingsNotificationBgServiceDesc'.tr,
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 22),
              secondary: const Icon(Icons.system_security_update_warning),
              enabled: PlatformInfo.isAndroid,
              title: Text('settingsNotificationBgService'.tr),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('holdToSeeDetail'.tr),
                  Text(
                    'needRestartToApply'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              value:
                  _prefs?.getBool('service_background_notification') ?? false,
              onChanged: (value) {
                _prefs
                    ?.setBool('service_background_notification', value ?? false)
                    .then((_) {
                  setState(() {});
                });
              },
            ),
          ),
          _buildCaptionHeader('update'.tr),
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            secondary: const Icon(Icons.sync_alt),
            title: Text('updateCheckStrictly'.tr),
            subtitle: Text('updateCheckStrictlyDesc'.tr),
            value: _prefs?.getBool('check_update_strictly') ?? false,
            onChanged: (value) {
              _prefs
                  ?.setBool('check_update_strictly', value ?? false)
                  .then((_) {
                setState(() {});
              });
            },
          ),
          Obx(() {
            final AuthProvider auth = Get.find<AuthProvider>();
            if (!auth.isAuthorized.value) return const SizedBox.shrink();
            return Column(
              children: [
                _buildCaptionHeader('account'.tr),
                ListTile(
                  leading: const Icon(Icons.flag),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                  title: Text('reportAbuse'.tr),
                  subtitle: Text('reportAbuseDesc'.tr),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AbuseReportDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                  title: Text('accountDeletion'.tr),
                  subtitle: Text('accountDeletionDesc'.tr),
                  onTap: () {
                    context
                        .showSlideToConfirmDialog(
                      'accountDeletionConfirm'.tr,
                      'accountDeletionConfirmDesc'.trParams({
                        'account': '@${auth.userProfile.value!['name']}',
                      }),
                    )
                        .then((value) async {
                      if (value != true) return;
                      final client = await auth.configureClient('id');
                      final resp = await client.post('/users/me/deletion', {});
                      if (resp.statusCode != 200) {
                        context.showErrorDialog(RequestException(resp));
                      } else {
                        context.showSnackbar('accountDeletionRequested'.tr);
                      }
                    });
                  },
                ),
              ],
            );
          }),
          _buildCaptionHeader('performance'.tr),
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            secondary: const Icon(Icons.message),
            title: Text('animatedMessageList'.tr),
            subtitle: Text('animatedMessageListDesc'.tr),
            value: _prefs?.getBool('non_animated_message_list') ?? false,
            onChanged: (value) {
              _prefs
                  ?.setBool('non_animated_message_list', value ?? false)
                  .then((_) {
                setState(() {});
              });
            },
          ),
          _buildCaptionHeader('more'.tr),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            trailing: const Icon(Icons.chevron_right),
            subtitle: FutureBuilder(
              future: AppDatabase.getDatabaseSize(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('localDatabaseSize'.trParams(
                    {'size': 'unknown'.tr},
                  ));
                }
                return Text('localDatabaseSize'.trParams(
                  {'size': snapshot.data!.formatBytes()},
                ));
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            title: Text('localDatabaseWipe'.tr),
            onTap: () {
              AppDatabase.removeDatabase().then((_) {
                setState(() {});
              });
            },
          ),
          if (PlatformInfo.canRateTheApp)
            ListTile(
              leading: const Icon(Icons.star),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: const EdgeInsets.symmetric(horizontal: 22),
              title: Text('rateTheApp'.tr),
              subtitle: Text('rateTheAppDesc'.tr),
              onTap: () {
                final inAppReview = InAppReview.instance;

                inAppReview.openStoreListing(
                  appStoreId: '6499032345',
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            title: Text('about'.tr),
            onTap: () {
              AppRouter.instance.pushNamed('about');
            },
          ),
        ],
      ),
    );
  }
}
