import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';

class PostCreatePopup extends StatelessWidget {
  final bool hideDraftBox;

  const PostCreatePopup({
    super.key,
    this.hideDraftBox = false,
  });

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    if (auth.isAuthorized.isFalse) {
      return const SizedBox.shrink();
    }

    final List<dynamic> actionList = [
      (
        icon: const Icon(Icons.post_add),
        label: 'postEditorModeStory'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed(
              'postEditor',
              queryParameters: {
                'mode': 0.toString(),
              },
            ),
          );
        },
      ),
      (
        icon: const Icon(Icons.description),
        label: 'postEditorModeArticle'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed(
              'postEditor',
              queryParameters: {
                'mode': 1.toString(),
              },
            ),
          );
        },
      ),
      (
        icon: const Icon(Icons.drafts),
        label: 'draftBoxOpen'.tr,
        onTap: () {
          Navigator.pop(
            context,
            AppRouter.instance.pushNamed('draftBox'),
          );
        },
      ),
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'postNew'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              children: actionList
                  .map((x) => Card(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: InkWell(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          onTap: x.onTap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              x.icon,
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  x.label,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ).paddingAll(18),
                        ),
                      ))
                  .toList(),
            ).paddingSymmetric(horizontal: 20),
          ),
        ],
      ),
    );
  }
}
