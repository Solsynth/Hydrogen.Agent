import 'dart:convert';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/theme.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/theme_switcher.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/reports/abuse_report.dart';
import 'package:solian/widgets/root_container.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  SharedPreferences? _prefs;
  String _docBasepath = '/';

  Widget _buildCaptionHeader(String title) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(title),
    );
  }

  static final List<SolianThemeData> _presentTheme = [
    SolianThemeData(
      id: 'themeColorRed',
      seedColor: const Color.fromRGBO(154, 98, 91, 1),
    ),
    SolianThemeData(
      id: 'themeColorBlue',
      seedColor: const Color.fromRGBO(103, 96, 193, 1),
    ),
    SolianThemeData(
      id: 'themeColorMiku',
      seedColor: const Color.fromRGBO(56, 120, 126, 1),
    ),
    SolianThemeData(
      id: 'themeColorKagamine',
      seedColor: const Color.fromRGBO(244, 183, 63, 1),
    ),
    SolianThemeData(
      id: 'themeColorLuka',
      seedColor: const Color.fromRGBO(243, 174, 218, 1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((dir) {
      _docBasepath = dir.path;
      if (mounted) {
        setState(() {});
      }
    });
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
          _buildCaptionHeader('theme'.tr),
          ListTile(
            leading: const Icon(Icons.palette),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            title: Text('globalTheme'.tr),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton2<SolianThemeData>(
                isExpanded: true,
                hint: Text(
                  'theme'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                items: _presentTheme
                    .map((SolianThemeData item) =>
                        DropdownMenuItem<SolianThemeData>(
                          value: item,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, color: item.seedColor),
                              const Gap(8),
                              Text(
                                item.id.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                value: (_prefs?.containsKey('global_theme') ?? false)
                    ? SolianThemeData.fromJson(
                        jsonDecode(_prefs!.getString('global_theme')!),
                      )
                    : null,
                onChanged: (SolianThemeData? value) {
                  context.read<ThemeSwitcher>().setThemeData(value);
                  setState(() {});
                },
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  height: 40,
                  width: 140,
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 40,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.military_tech),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22),
            title: Text('agedTheme'.tr),
            subtitle: Text('agedThemeDesc'.tr),
            value: _prefs?.getBool('aged_theme') ?? false,
            onChanged: (value) {
              if (value != null) {
                context.read<ThemeSwitcher>().setAgedTheme(value);
              }
              setState(() {});
            },
          ),
          if (!PlatformInfo.isWeb)
            ListTile(
              leading: const Icon(Icons.wallpaper),
              contentPadding: const EdgeInsets.only(left: 22, right: 31),
              title: Text('appBackgroundImage'.tr),
              subtitle: Text('appBackgroundImageDesc'.tr),
              trailing: File('$_docBasepath/app_background_image').existsSync()
                  ? const Icon(Icons.check_box)
                  : const Icon(Icons.check_box_outline_blank),
              onTap: () async {
                if (File('$_docBasepath/app_background_image').existsSync()) {
                  File('$_docBasepath/app_background_image').deleteSync();
                } else {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image == null) return;

                  await File(image.path)
                      .copy('$_docBasepath/app_background_image');
                }

                setState(() {});
              },
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
