import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/friend_select.dart';

class RealmMemberListPopup extends StatefulWidget {
  final Realm realm;

  const RealmMemberListPopup({
    super.key,
    required this.realm,
  });

  @override
  State<RealmMemberListPopup> createState() => _RealmMemberListPopupState();
}

class _RealmMemberListPopupState extends State<RealmMemberListPopup> {
  bool _isBusy = true;
  int? _accountId;

  List<RealmMember> _members = List.empty();

  void getProfile() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final prof = await auth.getProfile();
    setState(() => _accountId = prof.body['id']);
  }

  void getMembers() async {
    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];

    final resp = await client.get('/api/realms/${widget.realm.alias}/members');
    if (resp.statusCode == 200) {
      setState(() {
        _members = resp.body
            .map((x) => RealmMember.fromJson(x))
            .toList()
            .cast<RealmMember>();
      });
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  void promptAddMember() async {
    final input = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return FriendSelect(title: 'channelMembersAdd'.tr);
      },
    );
    if (input == null) return;

    addMember(input.name);
  }

  void addMember(String username) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.post(
      '/api/realms/${widget.realm.alias}/members',
      {'target': username},
    );
    if (resp.statusCode == 200) {
      getMembers();
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  void removeMember(RealmMember item) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.request(
      '/api/realms/${widget.realm.alias}/members',
      'delete',
      body: {'target': item.account.name},
    );
    if (resp.statusCode == 200) {
      getMembers();
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    getProfile();
    getMembers();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'realmMembers'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.person_add),
            title: Text('realmMembersAdd'.tr),
            subtitle: Text(
              'realmMembersAddHint'
                  .trParams({'realm': '#${widget.realm.alias}'}),
            ),
            onTap: () => promptAddMember(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                var element = _members[index];
                return ListTile(
                  title: Text(element.account.nick),
                  subtitle: Text(element.account.name),
                  leading: AccountAvatar(content: element.account.avatar),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const IconButton(
                        color: Colors.teal,
                        icon: Icon(Icons.admin_panel_settings),
                        onPressed: null,
                      ),
                      IconButton(
                        color: Colors.red,
                        icon: const Icon(Icons.remove_circle),
                        onPressed: element.account.externalId == _accountId
                            ? null
                            : () => removeMember(element),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
