import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';

class RealmListScreen extends StatefulWidget {
  const RealmListScreen({super.key});

  @override
  State<RealmListScreen> createState() => _RealmListScreenState();
}

class _RealmListScreenState extends State<RealmListScreen> {
  bool _isBusy = true;

  final List<Realm> _realms = List.empty(growable: true);

  getRealms() async {
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

    getRealms();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder(
        future: auth.isAuthorized,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.data == false) {
            return SigninRequiredOverlay(
              onSignedIn: () {
                getRealms();
              },
            );
          }

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverAppBar(
                      title: Text('realm'.tr),
                      centerTitle: false,
                      titleSpacing:
                          SolianTheme.isLargeScreen(context) ? null : 24,
                      forceElevated: innerBoxIsScrolled,
                      actions: [
                        const NotificationButton(),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            AppRouter.instance
                                .pushNamed('realmOrganizing')
                                .then(
                              (value) {
                                if (value != null) getRealms();
                              },
                            );
                          },
                        ),
                        SizedBox(
                          width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: MediaQuery.removePadding(
                removeTop: true,
                context: context,
                child: Column(
                  children: [
                    if (_isBusy)
                      const LinearProgressIndicator().animate().scaleX(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => getRealms(),
                        child: ListView.builder(
                          itemCount: _realms.length,
                          itemBuilder: (context, index) {
                            final element = _realms[index];
                            return buildRealm(element);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildRealm(Realm element) {
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
                    ),
                    const Positioned(
                      bottom: -30,
                      left: 18,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.indigo,
                        child: FaIcon(
                          FontAwesomeIcons.globe,
                          color: Colors.white,
                          size: 18,
                        ),
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
          onTap: () {},
        ),
      ),
    ).paddingOnly(left: 8, right: 8, bottom: 4);
  }
}
