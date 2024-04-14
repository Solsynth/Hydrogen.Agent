import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/common_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isAuthorized = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      var authorized = await context.read<AuthProvider>().isAuthorized();
      setState(() => isAuthorized = authorized);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return LayoutWrapper(
      title: AppLocalizations.of(context)!.account,
      child: isAuthorized
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  child: NameCard(),
                ),
                InkWell(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Sign out"),
                    ),
                  ),
                  onTap: () {
                    auth.signOff();
                    setState(() {
                      isAuthorized = false;
                    });
                  },
                )
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionCard(
                    icon: const Icon(Icons.login, color: Colors.white),
                    title: AppLocalizations.of(context)!.signIn,
                    caption: AppLocalizations.of(context)!.signInCaption,
                    onTap: () {
                      auth.signIn(context).then((_) {
                        auth.isAuthorized().then((val) {
                          setState(() => isAuthorized = val);
                        });
                      });
                    },
                  ),
                  ActionCard(
                    icon: const Icon(Icons.plus_one, color: Colors.white),
                    title: AppLocalizations.of(context)!.signUp,
                    caption: AppLocalizations.of(context)!.signUpCaption,
                    onTap: () {
                      launchUrl(getRequestUri('passport', '/auth/sign-up'));
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class NameCard extends StatelessWidget {
  const NameCard({super.key});

  Future<Widget> renderAvatar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profiles = await auth.getProfiles();
    return CircleAvatar(backgroundImage: NetworkImage(profiles["picture"]));
  }

  Future<Column> renderLabel(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profiles = await auth.getProfiles();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profiles["nick"],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(profiles["email"])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.indigo.withAlpha(30),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              FutureBuilder(
                future: renderAvatar(context),
                builder:
                    (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              const SizedBox(width: 20),
              FutureBuilder(
                future: renderLabel(context),
                builder:
                    (BuildContext context, AsyncSnapshot<Column> snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return const Column();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String caption;
  final Function onTap;

  const ActionCard(
      {super.key,
      required this.onTap,
      required this.title,
      required this.caption,
      required this.icon});

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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: icon,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(caption),
            ],
          ),
        ),
      ),
    );
  }
}
