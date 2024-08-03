import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_heading.dart';

class AccountProfilePopup extends StatefulWidget {
  final String name;

  const AccountProfilePopup({super.key, required this.name});

  @override
  State<AccountProfilePopup> createState() => _AccountProfilePopupState();
}

class _AccountProfilePopupState extends State<AccountProfilePopup> {
  bool _isBusy = true;

  Account? _userinfo;

  void _getUserinfo() async {
    setState(() => _isBusy = true);

    final client = ServiceFinder.configureClient('auth');
    final resp = await client.get('/users/${widget.name}');
    if (resp.statusCode == 200) {
      _userinfo = Account.fromJson(resp.body);
      setState(() => _isBusy = false);
    } else {
      context.showErrorDialog(resp.bodyString);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserinfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _userinfo == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountHeadingWidget(
            avatar: _userinfo!.avatar,
            banner: _userinfo!.banner,
            name: _userinfo!.name,
            nick: _userinfo!.nick,
            desc: _userinfo!.description,
            detail: _userinfo!,
            badges: _userinfo!.badges,
            status:
                Get.find<StatusProvider>().getSomeoneStatus(_userinfo!.name),
            extraWidgets: [
              Card(
                child: ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  title: Text('visitProfilePage'.tr),
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppRouter.instance.goNamed(
                      'accountProfilePage',
                      pathParameters: {'name': _userinfo!.name},
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ).paddingOnly(top: 16),
        ],
      ),
    );
  }
}
