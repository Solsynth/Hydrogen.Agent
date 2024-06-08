import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/auth/signin.dart';
import 'package:solian/screens/auth/signup.dart';
import 'package:solian/widgets/account/account_heading.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final actionItems = [
      (
        const Icon(Icons.color_lens),
        'accountPersonalize'.tr,
        'accountPersonalize'
      ),
      (const Icon(Icons.diversity_1), 'accountFriend'.tr, 'accountFriend'),
      (const Icon(Icons.info_outline), 'about'.tr, 'about'),
    ];

    final AuthProvider provider = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: FutureBuilder(
          future: provider.isAuthorized,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == false) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionCard(
                      icon: const Icon(Icons.login, color: Colors.white),
                      title: 'signin'.tr,
                      caption: 'signinCaption'.tr,
                      onTap: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          isDismissible: false,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const SignInPopup(),
                        ).then((_) async {
                          await provider.getProfile(noCache: true);
                          setState(() {});
                        });
                      },
                    ),
                    ActionCard(
                      icon: const Icon(Icons.add, color: Colors.white),
                      title: 'signup'.tr,
                      caption: 'signupCaption'.tr,
                      onTap: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          isDismissible: false,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const SignUpPopup(),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                const AccountHeading().paddingOnly(bottom: 8),
                ...(actionItems.map(
                  (x) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                    leading: x.$1,
                    title: Text(x.$2),
                    onTap: () {
                      AppRouter.instance
                          .pushNamed(x.$3)
                          .then((_) => setState(() {}));
                    },
                  ),
                )),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                  leading: const Icon(Icons.logout),
                  title: Text('signout'.tr),
                  onTap: () {
                    provider.signout();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AccountHeading extends StatelessWidget {
  const AccountHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider provider = Get.find();

    return FutureBuilder(
      future: provider.getProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final prof = snapshot.data!;
        return AccountHeadingWidget(
          avatar: prof.body['avatar'],
          banner: prof.body['banner'],
          name: prof.body['name'],
          nick: prof.body['nick'],
          desc: prof.body['description'],
          badges: prof.body['badges']
              ?.map((e) => AccountBadge.fromJson(e))
              .toList()
              .cast<AccountBadge>(),
        );
      },
    );
  }
}

class ActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String caption;
  final Function onTap;

  const ActionCard({
    super.key,
    required this.onTap,
    required this.title,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onTap(),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo,
                child: icon,
              ).paddingOnly(bottom: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  overflow: TextOverflow.clip,
                ),
              ),
              Text(
                caption,
                style: const TextStyle(overflow: TextOverflow.clip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
