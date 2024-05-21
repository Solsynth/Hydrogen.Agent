import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
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
      // (const Icon(Icons.color_lens), 'personalize'.tr, 'account.personalize'),
      // (const Icon(Icons.diversity_1), 'friend'.tr, 'account.friend'),
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
                      AppRouter.instance.pushNamed('signin').then((_) {
                        setState(() {});
                      });
                    },
                  ),
                  ActionCard(
                    icon: const Icon(Icons.add, color: Colors.white),
                    title: 'signup'.tr,
                    caption: 'signupCaption'.tr,
                    onTap: () {
                      AppRouter.instance.pushNamed('signup');
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
                    AppRouter.instance.pushNamed(x.$3);
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Material(
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.only(left: 22, right: 34, top: 4, bottom: 4),
            leading: AccountAvatar(
                content: snapshot.data!.body?['avatar'], radius: 24),
            title: Text(snapshot.data!.body?['nick']),
            subtitle: Text(snapshot.data!.body?['email']),
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
