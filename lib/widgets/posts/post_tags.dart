import 'package:flutter/material.dart';
import 'package:solian/models/post_categories.dart';
import 'package:solian/router.dart';

class PostTagsList extends StatelessWidget {
  final List<Tag> tags;

  const PostTagsList({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 6,
      children: tags
          .map(
            (x) => InkWell(
              child: Text(
                '#${x.alias}',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                AppRouter.instance.pushNamed('feedSearch', queryParameters: {
                  'tag': x.alias,
                });
              },
            ),
          )
          .toList(),
    );
  }
}
