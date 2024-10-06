import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/services.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/auto_cache_image.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:solian/widgets/sized_container.dart';

class RealmListScreen extends StatefulWidget {
  const RealmListScreen({super.key});

  @override
  State<RealmListScreen> createState() => _RealmListScreenState();
}

class _RealmListScreenState extends State<RealmListScreen> {
  bool _isBusy = true;

  final List<Realm> _realms = List.empty(growable: true);

  _getRealms() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final RealmProvider provider = Get.find();
    final resp = await provider.listAvailableRealm();

    setState(() {
      _realms.clear();
      _realms.addAll(
        resp.body.map((e) => Realm.fromJson(e)).toList().cast<Realm>(),
      );
    });

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    _getRealms();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return RootContainer(
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('realm'.tr),
          centerTitle: true,
          toolbarHeight: AppTheme.toolbarHeight(context),
          actions: [
            const BackgroundStateWidget(),
            const NotificationButton(),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                AppRouter.instance.pushNamed('realmOrganizing').then(
                  (value) {
                    if (value != null) _getRealms();
                  },
                );
              },
            ),
            SizedBox(
              width: AppTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
        ),
        body: Obx(() {
          if (auth.isAuthorized.isFalse) {
            return SigninRequiredOverlay(
              onDone: () => _getRealms(),
            );
          }

          return Column(
            children: [
              if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
              Expanded(
                child: CenteredContainer(
                  child: RefreshIndicator(
                    onRefresh: () => _getRealms(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _realms.length,
                      itemBuilder: (context, index) {
                        final element = _realms[index];
                        return _buildEntry(element);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEntry(Realm element) {
    return Card(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: (element.banner?.isEmpty ?? true)
                          ? const SizedBox.shrink()
                          : AutoCacheImage(
                              ServiceFinder.buildUrl(
                                'uc',
                                '/attachments/${element.banner}',
                              ),
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: 18,
                      child: (element.avatar?.isEmpty ?? true)
                          ? CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: const FaIcon(
                                FontAwesomeIcons.globe,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : AccountAvatar(
                              content: element.avatar!,
                              bgColor: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ],
                ),
              ).paddingOnly(bottom: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(element.name),
                subtitle: Text(
                  element.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
          onTap: () {
            AppRouter.instance.pushNamed('realmView', pathParameters: {
              'alias': element.alias,
            });
          },
        ),
      ),
    ).paddingOnly(left: 8, right: 8, bottom: 4);
  }
}
