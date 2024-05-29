import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _isBusy = true;
  int? _accountId;

  final List<Channel> _channels = List.empty(growable: true);

  getProfile() async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    _accountId = prof.body['id'];
  }

  getChannels() async {
    setState(() => _isBusy = true);

    final ChannelProvider provider = Get.find();
    final resp = await provider.listAvailableChannel();

    setState(() {
      _channels.clear();
      _channels.addAll(
        resp.body.map((e) => Channel.fromJson(e)).toList().cast<Channel>(),
      );
    });

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    getProfile();
    getChannels();
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
                getChannels();
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => getChannels(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text('contact'.tr),
                  centerTitle: false,
                  titleSpacing: SolianTheme.isLargeScreen(context) ? null : 24,
                  actions: [
                    const NotificationButton(),
                    PopupMenuButton(
                      icon: const Icon(Icons.add_circle),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          child: ListTile(
                            title: Text('channelOrganizeCommon'.tr),
                            leading: const Icon(Icons.tag),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onTap: () {
                            AppRouter.instance
                                .pushNamed('channelOrganizing')
                                .then(
                              (value) {
                                if (value != null) getChannels();
                              },
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            title: Text('channelOrganizeDirect'.tr),
                            leading: const FaIcon(
                              FontAwesomeIcons.userGroup,
                              size: 16,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onTap: () {
                            final ChannelProvider provider = Get.find();
                            provider
                                .createDirectChannel(context, 'global')
                                .then((resp) {
                              if (resp != null) {
                                getChannels();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                    ),
                  ],
                ),
                if (_isBusy)
                  SliverToBoxAdapter(
                    child: const LinearProgressIndicator().animate().scaleX(),
                  ),
                SliverList.builder(
                  itemCount: _channels.length,
                  itemBuilder: (context, index) {
                    final element = _channels[index];
                    return buildItem(element);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildItem(Channel element) {
    if (element.type == 1) {
      final otherside = element.members!
          .where((e) => e.account.externalId != _accountId)
          .first;

      return ListTile(
        leading: AccountAvatar(
          content: otherside.account.avatar,
          bgColor: Colors.indigo,
          feColor: Colors.white,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(otherside.account.nick),
        subtitle: Text(
          'channelDirectDescription'
              .trParams({'username': '@${otherside.account.name}'}),
        ),
        onTap: () {
          AppRouter.instance.pushNamed(
            'channelChat',
            pathParameters: {'alias': element.alias},
            queryParameters: {
              if (element.realmId != null) 'realm': element.realm!.alias,
            },
          );
        },
      );
    }

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.indigo,
        child: FaIcon(
          FontAwesomeIcons.hashtag,
          color: Colors.white,
          size: 16,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(element.name),
      subtitle: Text(element.description),
      onTap: () {
        AppRouter.instance.pushNamed(
          'channelChat',
          pathParameters: {'alias': element.alias},
          queryParameters: {
            if (element.realmId != null) 'realm': element.realm!.alias,
          },
        );
      },
    );
  }
}
