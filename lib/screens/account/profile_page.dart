import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/controllers/post_list_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/services.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/feed/feed_list.dart';
import 'package:solian/widgets/sized_container.dart';

import '../../widgets/attachments/attachment_list.dart';

class AccountProfilePage extends StatefulWidget {
  final String name;

  const AccountProfilePage({super.key, required this.name});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  late final PostListController _postController;
  final PagingController<int, Attachment> _albumPagingController =
      PagingController(firstPageKey: 0);

  bool _isBusy = true;
  bool _showMature = false;

  Account? _userinfo;

  Future<void> getUserinfo() async {
    setState(() => _isBusy = true);

    final client = ServiceFinder.configureClient('auth');
    final resp = await client.get('/users/${widget.name}');
    if (resp.statusCode == 200) {
      _userinfo = Account.fromJson(resp.body);
      setState(() => _isBusy = false);
    } else {
      context.showErrorDialog(resp.bodyString).then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _postController = PostListController(author: widget.name);
    _albumPagingController.addPageRequestListener((pageKey) async {
      final client = ServiceFinder.configureClient('files');
      final resp = await client
          .get('/attachments?take=10&offset=$pageKey&author=${widget.name}');
      if (resp.statusCode == 200) {
        final result = PaginationResult.fromJson(resp.body);
        final out = result.data
            ?.map((e) => Attachment.fromJson(e))
            .where((x) => x.mimetype.split('/').firstOrNull == 'image')
            .toList();
        if (out != null && result.data!.length >= 10) {
          _albumPagingController.appendPage(out, pageKey + out.length);
        } else if (out != null) {
          _albumPagingController.appendLastPage(out);
        }
      } else {
        _albumPagingController.error = resp.bodyString;
      }
    });
    getUserinfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _userinfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                centerTitle: false,
                floating: true,
                toolbarHeight: SolianTheme.toolbarHeight(context),
                leadingWidth: 24,
                automaticallyImplyLeading: false,
                flexibleSpace: Row(
                  children: [
                    AppBarLeadingButton.adaptive(context) ??
                        const SizedBox(width: 8),
                    const SizedBox(width: 8),
                    if (_userinfo != null)
                      AccountAvatar(content: _userinfo!.avatar, radius: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userinfo != null)
                            Text(
                              _userinfo!.nick,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          if (_userinfo != null)
                            Text(
                              '@${_userinfo!.name}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const BackgroundStateWidget(),
                    const NotificationButton(),
                    SizedBox(
                      width: SolianTheme.isLargeScreen(context) ? 8 : 16,
                    ),
                  ],
                ),
                bottom: TabBar(
                  tabs: [
                    Tab(text: 'profilePosts'.tr),
                    Tab(text: 'profileAlbum'.tr),
                  ],
                ),
              )
            ];
          },
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              RefreshIndicator(
                onRefresh: () => _postController.reloadAllOver(),
                child: CustomScrollView(slivers: [
                  if (_userinfo == null)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_userinfo != null)
                    FeedListWidget(
                      controller: _postController.pagingController,
                    ),
                ]),
              ),
              CenteredContainer(
                child: RefreshIndicator(
                  onRefresh: () =>
                      Future.sync(() => _albumPagingController.refresh()),
                  child: PagedGridView<int, Attachment>(
                    padding: EdgeInsets.zero,
                    pagingController: _albumPagingController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<Attachment>(
                      itemBuilder: (BuildContext context, item, int index) {
                        const radius = BorderRadius.all(Radius.circular(8));
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 0.3,
                            ),
                            borderRadius: radius,
                          ),
                          child: ClipRRect(
                            borderRadius: radius,
                            child: AttachmentListEntry(
                              item: item,
                              parentId: 'album',
                              showMature: _showMature,
                              onReveal: (value) {
                                setState(() => _showMature = value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ).paddingAll(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
