import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/post_explore.dart';
import 'package:solian/widgets/posts/post_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageKey = 0;
  int? _dataTotal;

  bool _isFirstLoading = true;

  final List<Post> _data = List.empty(growable: true);

  getPosts() async {
    if (_dataTotal != null && _pageKey * 10 > _dataTotal!) return;

    final PostExploreProvider provider = Get.find();
    final resp = await provider.listPost(_pageKey);
    final PaginationResult result = PaginationResult.fromJson(resp.body);

    setState(() {
      final parsed = result.data?.map((e) => Post.fromJson(e));
      if (parsed != null) _data.addAll(parsed);
      _isFirstLoading = false;
      _dataTotal = result.count;
      _pageKey++;
    });
  }

  @override
  void initState() {
    Get.lazyPut(() => PostExploreProvider());
    super.initState();

    Future.delayed(Duration.zero, () => getPosts());
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => getPosts(),
      child: ListView.separated(
        itemCount: _data.length,
        itemBuilder: (BuildContext context, int index) {
          final item = _data[index];
          return InkWell(
            child: PostItem(item: item).paddingSymmetric(horizontal: 18, vertical: 8),
            onTap: () {},
          );
        },
        separatorBuilder: (_, __) => const Divider(thickness: 0.3),
      ),
    );
  }
}
