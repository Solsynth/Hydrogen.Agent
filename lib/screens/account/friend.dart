import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/friendship.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/widgets/account/account_avatar.dart';

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

  DismissDirection getDismissDirection(Friendship relation) {
    if (relation.status == 2) return DismissDirection.endToStart;
    if (relation.status == 1) return DismissDirection.startToEnd;
    if (relation.status == 0 && relation.relatedId != _accountId) {
      return DismissDirection.startToEnd;
    }
    return DismissDirection.horizontal;
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

  Widget buildFriendshipItem(context, index, status) {
    final element = filterWithStatus(status)[index];
    final otherside = element.getOtherside(_accountId!);

    final randomId = DateTime.now().microsecondsSinceEpoch >> 10;

    return Dismissible(
      key: Key(randomId.toString()),
      background: Container(
        color: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.close, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      direction: getDismissDirection(element),
      child: ListTile(
        title: Text(otherside.nick),
        subtitle: Text(otherside.name),
        leading: AccountAvatar(content: otherside.avatar),
      ),
      onDismissed: (direction) async {
        final FriendProvider provider = Get.find();
        if (direction == DismissDirection.startToEnd) {
          await provider.updateFriendship(element, 2);
          await getFriendship();
        }
        if (direction == DismissDirection.endToStart) {
          await provider.updateFriendship(element, 1);
          await getFriendship();
        }
      },
    );
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
                  onTap: () {},
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
                  onTap: () {},
                ),
              ),
              SliverList.builder(
                itemCount: filterWithStatus(1).length,
                itemBuilder: (_, __) => buildFriendshipItem(_, __, 1),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.8),
                      width: 0.3,
                    )),
                  ),
                  padding: const EdgeInsets.only(top: 16, bottom: 32),
                  child: Text(
                    'accountFriendListHint'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
