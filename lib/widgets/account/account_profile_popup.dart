import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_heading.dart';

class AccountProfilePopup extends StatefulWidget {
  final Account account;

  const AccountProfilePopup({super.key, required this.account});

  @override
  State<AccountProfilePopup> createState() => _AccountProfilePopupState();
}

class _AccountProfilePopupState extends State<AccountProfilePopup> {
  bool _isBusy = true;

  Account? _userinfo;

  void getUserinfo() async {
    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.buildUrl('auth', null);

    final resp = await client.get('/users/${widget.account.name}');
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

    getUserinfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _userinfo == null) {
      return const Center(child: CircularProgressIndicator());
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
            status: Get.find<StatusProvider>().getSomeoneStatus(_userinfo!.name),
          ).paddingOnly(top: 16),
        ],
      ),
    );
  }
}
