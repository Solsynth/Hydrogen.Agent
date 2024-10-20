import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/account/relative_select.dart';
import 'package:solian/widgets/loading_indicator.dart';

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
    if (auth.isAuthorized.isFalse) return;

    setState(() => _accountId = auth.userProfile.value!['id']);
  }

  void getMembers() async {
    setState(() => _isBusy = true);

    final client = await ServiceFinder.configureClient('auth');

    final resp = await client.get('/realms/${widget.realm.alias}/members');
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
        return RelativeSelector(title: 'channelMembersAdd'.tr);
      },
    );
    if (input == null) return;

    addMember(input.name);
  }

  void addMember(String username) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final client = await auth.configureClient('auth');

    final resp = await client.post(
      '/realms/${widget.realm.alias}/members',
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
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final client = await auth.configureClient('auth');

    final resp = await client.request(
      '/realms/${widget.realm.alias}/members',
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
          LoadingIndicator(isActive: _isBusy),
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
                  leading: GestureDetector(
                    child:
                        AttachedCircleAvatar(content: element.account.avatar),
                    onTap: () {
                      showModalBottomSheet(
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        context: context,
                        builder: (context) => AccountProfilePopup(
                          name: element.account.name,
                        ),
                      );
                    },
                  ),
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
                        onPressed: element.account.id == _accountId
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
