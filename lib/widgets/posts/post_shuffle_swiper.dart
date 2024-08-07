import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_list_controller.dart';
import 'package:solian/widgets/posts/post_single_display.dart';
import 'package:solian/widgets/sized_container.dart';

class PostShuffleSwiper extends StatefulWidget {
  final PostListController controller;

  const PostShuffleSwiper({super.key, required this.controller});

  @override
  State<PostShuffleSwiper> createState() => _PostShuffleSwiperState();
}

class _PostShuffleSwiperState extends State<PostShuffleSwiper> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CardSwiper(
        initialIndex: 0,
        isLoop: false,
        controller: _swiperController,
        cardsCount: widget.controller.postTotal.value,
        numberOfCardsDisplayed: 2,
        allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
          horizontal: true,
        ),
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          if (widget.controller.postList.length <= index) {
            return Card(
              child: const Center(
                child: CircularProgressIndicator(),
              ).paddingAll(24),
            );
          }
          final element = widget.controller.postList[index];
          return CenteredContainer(
            child: PostSingleDisplay(
              key: Key('p${element.id}'),
              item: element,
              onUpdate: () {
                widget.controller.reloadAllOver();
              },
            ),
          );
        },
        padding: const EdgeInsets.all(24),
        onSwipe: (prevIndex, currIndex, dir) {
          if (prevIndex + 2 >= widget.controller.postList.length) {
            // Automatically load more
            widget.controller.loadMore();
          }
          return true;
        },
      ).paddingOnly(bottom: MediaQuery.of(context).padding.bottom),
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }
}
