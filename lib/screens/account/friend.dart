import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/widgets/account/friend_list.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  bool _isBusy = false;
  int? _accountId;

  List<Friendship> _friendships = List.empty();

  List<Friendship> filterWithStatus(int status) {
    return _friendships.where((x) => x.status == status).toList();
  }

  Future<void> getFriendship() async {
    setState(() => _isBusy = true);

    final FriendProvider provider = Get.find();
    final resp = await provider.listFriendship();

    setState(() {
      _friendships = resp.body
          .map((e) => Friendship.fromJson(e))
          .toList()
          .cast<Friendship>();
      _isBusy = false;
    });
  }

  void showScopedListPopup(String title, int status) {
    showModalBottomSheet(
      useRootNavigator: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverFriendList(
                      accountId: _accountId!,
                      items: filterWithStatus(status),
                      onUpdate: () {
                        getFriendship();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void promptAddFriend() async {
    final FriendProvider provider = Get.find();

    final controller = TextEditingController();
    final input = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('accountFriendNew'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('accountFriendNewHint'.tr, textAlign: TextAlign.left),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'username'.tr,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            TextButton(
              child: Text('next'.tr),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (input == null || input.isEmpty) return;

    try {
      setState(() => _isBusy = true);
      await provider.createFriendship(input);
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  @override
  void initState() {
    Get.find<AuthProvider>().getProfile().then((value) {
      _accountId = value.body['id'];
    });
    super.initState();

    Future.delayed(Duration.zero, () => getFriendship());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => promptAddFriend(),
        ),
        body: RefreshIndicator(
          onRefresh: () => getFriendship(),
          child: CustomScrollView(
            slivers: [
              if (_isBusy)
                SliverToBoxAdapter(
                  child: const LinearProgressIndicator().animate().scaleX(),
                ),
              SliverToBoxAdapter(
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.person_add),
                  trailing: const Icon(Icons.chevron_right),
                  title: Text(
                    '${'accountFriendPending'.tr} (${filterWithStatus(0).length})',
                  ),
                  onTap: () =>
                      showScopedListPopup('accountFriendPending'.tr, 0),
                ),
              ),
              SliverToBoxAdapter(
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.block),
                  trailing: const Icon(Icons.chevron_right),
                  title: Text(
                    '${'accountFriendBlocked'.tr} (${filterWithStatus(2).length})',
                  ),
                  onTap: () =>
                      showScopedListPopup('accountFriendBlocked'.tr, 2),
                ),
              ),
              SliverFriendList(
                accountId: _accountId!,
                items: filterWithStatus(1),
                onUpdate: () {
                  getFriendship();
                },
              ),
              const SliverToBoxAdapter(
                child: Divider(thickness: 0.3, height: 0.3),
              ),
              SliverToBoxAdapter(
                child: Text(
                  'accountFriendListHint'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ).paddingOnly(top: 16, bottom: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
