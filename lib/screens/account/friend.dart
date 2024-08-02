import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/relations.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/relative_list.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isBusy = false;

  List<Relationship> _relations = List.empty();

  List<Relationship> _filterByStatus(int status) {
    return _relations.where((x) => x.status == status).toList();
  }

  Future<void> _loadRelations() async {
    setState(() => _isBusy = true);

    final RelationshipProvider relations = Get.find();
    final resp = await relations.listRelation();

    setState(() {
      _relations = resp.body
          .map((e) => Relationship.fromJson(e))
          .toList()
          .cast<Relationship>();
      _isBusy = false;
    });

    relations.friendRequestCount.value =
        _relations.where((x) => x.status == 0).length;
  }

  void promptAddFriend() async {
    final RelationshipProvider provider = Get.find();

    final controller = TextEditingController();
    final input = await showDialog<String?>(
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
      await provider.makeFriend(input);
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _loadRelations().then((_) {
      if (_filterByStatus(0).isEmpty) {
        _tabController.animateTo(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text('accountFriend'.tr),
          actions: [
            if (_isBusy)
              SizedBox(
                height: 48,
                width: 48,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                ).paddingAll(14),
              ),
            SizedBox(
              width: SolianTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.call_received)),
              Tab(icon: Icon(Icons.people)),
              Tab(icon: Icon(Icons.call_made)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => promptAddFriend(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: () => _loadRelations(),
              child: CustomScrollView(
                slivers: [
                  SilverRelativeList(
                    items: _filterByStatus(0),
                    onUpdate: () => _loadRelations(),
                  ),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: () => _loadRelations(),
              child: CustomScrollView(
                slivers: [
                  SilverRelativeList(
                    items: _filterByStatus(1),
                    onUpdate: () => _loadRelations(),
                  ),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: () => _loadRelations(),
              child: CustomScrollView(
                slivers: [
                  SilverRelativeList(
                    items: _filterByStatus(3),
                    onUpdate: () => _loadRelations(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
