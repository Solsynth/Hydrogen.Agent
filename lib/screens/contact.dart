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
import 'package:solian/widgets/account/signin_required_overlay.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _isBusy = true;

  final List<Channel> _channels = List.empty(growable: true);

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

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverAppBar(
                      title: Text('contact'.tr),
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
                                .pushNamed('channelOrganizing')
                                .then(
                              (value) {
                                if (value != null) getChannels();
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
                        onRefresh: () => getChannels(),
                        child: ListView.builder(
                          itemCount: _channels.length,
                          itemBuilder: (context, index) {
                            final element = _channels[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: FaIcon(
                                  element.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              title: Text(element.name),
                              subtitle: Text(element.description),
                              onTap: () {
                                AppRouter.instance.pushNamed(
                                  'channelChat',
                                  pathParameters: {'alias': element.alias},
                                  queryParameters: {
                                    if (element.realmId != null)
                                      'realm': element.realm!.alias,
                                  },
                                );
                              },
                            );
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
}
