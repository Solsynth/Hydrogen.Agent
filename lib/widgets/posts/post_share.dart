import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/root_container.dart';

class PostShareImage extends StatelessWidget {
  final Post item;

  const PostShareImage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
    return RootContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(8),
          Material(
            color: Colors.transparent,
            child: Card(
              child: PostItem(
                item: item,
                isShowEmbed: true,
                isClickable: false,
                showFeaturedReply: false,
                isReactable: false,
                isShowReply: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                onComment: () {},
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'shareImageFooter'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Solsynth LLC © ${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: QrImageView(
                    data: 'https://solsynth.dev/posts/${item.id}',
                    version: QrVersions.auto,
                    padding: const EdgeInsets.all(4),
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        ],
      ).paddingSymmetric(horizontal: 36, vertical: 24),
    );
  }
}
