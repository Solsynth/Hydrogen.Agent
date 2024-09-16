import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class AccountSelector extends StatefulWidget {
  final String title;
  final Widget? Function(Account item)? trailingBuilder;
  final List<int>? initialSelection;
  final Function(List<Account>)? onMultipleSelect;

  const AccountSelector({
    super.key,
    required this.title,
    this.trailingBuilder,
    this.initialSelection,
    this.onMultipleSelect,
  });

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  final TextEditingController _probeController = TextEditingController();

  final List<Account> _relativeUsers = List.empty(growable: true);
  final List<Account> _pendingUsers = List.empty(growable: true);
  final List<Account> _selectedUsers = List.empty(growable: true);

  int _accountId = 0;

  _revertSelectedUsers() async {
    if (widget.initialSelection?.isEmpty ?? true) return;
    final client = await ServiceFinder.configureClient('auth');
    final idQuery = widget.initialSelection!.join(',');
    final resp = await client.get('/users?id=$idQuery');

    setState(() {
      _selectedUsers.addAll(
        resp.body.map((e) => Account.fromJson(e)).toList().cast<Account>(),
      );
    });
  }

  _getFriends() async {
    final AuthProvider auth = Get.find();
    _accountId = auth.userProfile.value!['id'];

    final RelationshipProvider provider = Get.find();
    final resp = await provider.listRelationWithStatus(1);

    setState(() {
      _relativeUsers.addAll(
        resp.body
            .map((e) => Relationship.fromJson(e).related)
            .toList()
            .cast<Account>(),
      );
    });
  }

  _searchAccount() async {
    final AuthProvider auth = Get.find();
    _accountId = auth.userProfile.value!['id'];

    if (_probeController.text.isEmpty) return;

    final client = await auth.configureClient('auth');
    final resp = await client.get(
      '/users/search?probe=${_probeController.text}',
    );

    setState(() {
      _pendingUsers.clear();
      _pendingUsers.addAll(
        resp.body.map((e) => Account.fromJson(e)).toList().cast<Account>(),
      );
    });
  }

  bool _checkSelected(Account item) {
    return _selectedUsers.any((x) => x.id == item.id);
  }

  @override
  void initState() {
    super.initState();
    _getFriends();
    _revertSelectedUsers();
  }

  @override
  void dispose() {
    super.dispose();
    _probeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Container(
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: TextField(
              controller: _probeController,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'search'.tr,
              ),
              onSubmitted: (_) {
                _searchAccount();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pendingUsers.isEmpty
                  ? _relativeUsers.length
                  : _pendingUsers.length,
              itemBuilder: (context, index) {
                var element = _pendingUsers.isEmpty
                    ? _relativeUsers[index]
                    : _pendingUsers[index];
                return ListTile(
                  title: Text(element.nick),
                  subtitle: Text(element.name),
                  leading: AccountAvatar(content: element.avatar),
                  trailing: widget.trailingBuilder != null
                      ? widget.trailingBuilder!(element)
                      : _checkSelected(element)
                          ? const Icon(Icons.check)
                          : null,
                  onTap: element.id == _accountId
                      ? null
                      : () {
                          if (widget.onMultipleSelect == null) {
                            Navigator.pop(context, element);
                            return;
                          }

                          setState(() {
                            final idx = _selectedUsers
                                .indexWhere((x) => x.id == element.id);
                            if (idx != -1) {
                              _selectedUsers.removeAt(idx);
                            } else {
                              _selectedUsers.add(element);
                            }
                          });
                          widget.onMultipleSelect!(_selectedUsers);
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
