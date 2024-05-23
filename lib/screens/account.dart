import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/auth/signin.dart';
import 'package:solian/screens/auth/signup.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';

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
    ];

    final AuthProvider provider = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
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
              const AccountNameCard().paddingOnly(bottom: 8),
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
    );
  }
}

class AccountNameCard extends StatelessWidget {
  const AccountNameCard({super.key});

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
        return Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      if (prof.body['banner'] != null)
                        Image.network(
                          '${ServiceFinder.services['paperclip']}/api/attachments/${prof.body['banner']}',
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        bottom: -30,
                        left: 18,
                        child: AccountAvatar(
                          content: prof.body['avatar'],
                          radius: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    prof.body['nick'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ).paddingOnly(right: 4),
                  Text(
                    '@${prof.body['name']}',
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ).paddingOnly(left: 120, top: 8),
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: ListTile(
                    title: Text('description'.tr),
                    subtitle: Text(
                      prof.body['description']?.isNotEmpty
                          ? prof.body['description']
                          : 'No description yet.',
                    ),
                  ),
                ),
              ).paddingOnly(left: 24, right: 24, top: 8),
            ],
          ),
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
