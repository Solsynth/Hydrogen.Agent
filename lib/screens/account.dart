import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/widgets/account/avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/empty.dart';
import 'package:solian/widgets/indent_wrapper.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _title;
  String? _selectedTab;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    Widget renderContent() {
      switch (_selectedTab) {
        case 'account.friend':
          return const FriendScreenWidget();
        default:
          return const SelectionEmptyWidget();
      }
    }

    return IndentWrapper(
      title: _title ?? AppLocalizations.of(context)!.account,
      noSafeArea: true,
      fixedAppBarColor: true,
      child: isLargeScreen
          ? Row(
              children: [
                Flexible(
                  flex: 2,
                  child: AccountScreenWidget(
                    onSelect: (item, title) {
                      setState(() {
                        _selectedTab = item;
                        _title = title;
                      });
                    },
                  ),
                ),
                const VerticalDivider(thickness: 0.3, width: 0.3),
                Flexible(flex: 4, child: renderContent()),
              ],
            )
          : AccountScreenWidget(
              onSelect: (item, _) {
                router.pushNamed(item);
              },
            ),
    );
  }
}

class AccountScreenWidget extends StatefulWidget {
  final Function(String item, String title) onSelect;

  const AccountScreenWidget({super.key, required this.onSelect});

  @override
  State<AccountScreenWidget> createState() => _AccountScreenWidgetState();
}

class _AccountScreenWidgetState extends State<AccountScreenWidget> {
  bool _isAuthorized = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      var authorized = await context.read<AuthProvider>().isAuthorized();
      setState(() => _isAuthorized = authorized);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_isAuthorized) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: NameCard(),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 34),
            leading: const Icon(Icons.diversity_1),
            title: Text(AppLocalizations.of(context)!.friend),
            onTap: () {
              widget.onSelect('account.friend', AppLocalizations.of(context)!.friend);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 34),
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)!.signOut),
            onTap: () {
              auth.signoff();
              setState(() {
                _isAuthorized = false;
              });
            },
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionCard(
              icon: const Icon(Icons.login, color: Colors.white),
              title: AppLocalizations.of(context)!.signIn,
              caption: AppLocalizations.of(context)!.signInCaption,
              onTap: () {
                router.pushNamed('auth.sign-in').then((did) {
                  auth.isAuthorized().then((value) {
                    setState(() => _isAuthorized = value);
                  });
                });
              },
            ),
            ActionCard(
              icon: const Icon(Icons.add, color: Colors.white),
              title: AppLocalizations.of(context)!.signUp,
              caption: AppLocalizations.of(context)!.signUpCaption,
              onTap: () {
                router.pushNamed('auth.sign-up');
              },
            ),
          ],
        ),
      );
    }
  }
}

class NameCard extends StatelessWidget {
  const NameCard({super.key});

  Future<Widget> renderAvatar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profiles = await auth.getProfiles();
    return AccountAvatar(source: profiles['picture'], direct: true);
  }

  Future<Column> renderLabel(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profiles = await auth.getProfiles();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profiles['nick'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(profiles['email'])
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
                builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
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
                builder: (BuildContext context, AsyncSnapshot<Column> snapshot) {
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

  const ActionCard({super.key, required this.onTap, required this.title, required this.caption, required this.icon});

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
