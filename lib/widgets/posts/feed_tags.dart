import 'package:flutter/material.dart';
import 'package:solian/models/feed.dart';

class FeedTagsList extends StatelessWidget {
  final List<Tag> tags;

  const FeedTagsList({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(
      Radius.circular(8),
    );

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 6,
      children: tags
          .map(
            (x) => GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Theme.of(context).colorScheme.primary,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Text(
                  '#${x.alias}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {},
            ),
          )
          .toList(),
    );
  }
}
