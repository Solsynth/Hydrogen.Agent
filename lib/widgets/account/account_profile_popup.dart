import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';

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
    client.httpClient.baseUrl = ServiceFinder.services['passport'];

    final resp = await client.get('/api/users/${widget.account.name}');
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
    if (_isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  if (_userinfo!.banner != null)
                    Image.network(
                      '${ServiceFinder.services['paperclip']}/api/attachments/${_userinfo!.banner}',
                      fit: BoxFit.cover,
                    ),
                  Positioned(
                    bottom: -30,
                    left: 18,
                    child: AccountAvatar(
                      content: widget.account.banner,
                      radius: 48,
                    ),
                  ),
                ],
              ),
            ),
          ).paddingOnly(top: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _userinfo!.nick,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(right: 4),
              Text(
                '@${_userinfo!.name}',
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],
          ).paddingOnly(left: 120, top: 8),
          SizedBox(
            width: double.infinity,
            child: Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: ListTile(
                title: Text('description'.tr),
                subtitle: Text(
                  _userinfo!.description.isNotEmpty
                      ? widget.account.description
                      : 'No description yet.',
                ),
              ),
            ),
          ).paddingOnly(left: 24, right: 24, top: 8),
        ],
      ),
    );
  }
}
