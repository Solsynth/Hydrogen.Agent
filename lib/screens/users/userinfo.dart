import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/personal_page.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/personal_page_content.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';

class UserInfoScreen extends StatefulWidget {
  final String name;

  const UserInfoScreen({super.key, required this.name});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _client = Client();

  Account? _userinfo;
  PersonalPage? _page;

  Future<Account> fetchUserinfo() async {
    final res = await Future.wait([
      _client.get(getRequestUri('passport', '/api/users/${widget.name}')),
      _client.get(getRequestUri('passport', '/api/users/${widget.name}/page'))
    ], eagerError: true);
    final mistakeRes = res.indexWhere((x) => x.statusCode != 200 && x.statusCode != 400);
    if (mistakeRes > -1) {
      var message = utf8.decode(res[mistakeRes].bodyBytes);
      context.showErrorDialog(message);
      throw Exception(message);
    } else {
      final info = Account.fromJson(jsonDecode(utf8.decode(res[0].bodyBytes)));
      final page = res[1].statusCode == 200 ? PersonalPage.fromJson(jsonDecode(utf8.decode(res[1].bodyBytes))) : null;
      setState(() {
        _userinfo = info;
        _page = page ??
            PersonalPage(
              id: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              content: '',
              script: '',
              style: '',
              accountId: info.id,
            );
      });
      return info;
    }
  }

  String getAuthorDescribe() => _userinfo!.description.isNotEmpty ? _userinfo!.description : 'No description yet.';

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: _userinfo?.nick ?? 'Loading...',
      fixedAppBarColor: SolianTheme.isLargeScreen(context),
      hideDrawer: true,
      body: FutureBuilder(
        future: fetchUserinfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: AspectRatio(
                  aspectRatio: 16 / 5,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: _userinfo?.banner != null
                        ? CachedNetworkImage(
                            imageUrl: getRequestUri('passport', '/api/avatar/${_userinfo!.banner}').toString(),
                            fit: BoxFit.cover,
                            progressIndicatorBuilder: (_, __, DownloadProgress loadingProgress) {
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.totalSize != null
                                      ? loadingProgress.downloaded / loadingProgress.totalSize!
                                      : null,
                                ),
                              );
                            },
                          )
                        : Container(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
                child: Row(
                  children: [
                    AccountAvatar(source: _userinfo!.avatar, radius: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              Text(
                                _userinfo!.nick,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '@${_userinfo!.name}',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _userinfo!.description,
                            maxLines: 3,
                            style: const TextStyle(
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(thickness: 0.3, indent: 4, endIndent: 4),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PersonalPageContent(item: _page!),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
