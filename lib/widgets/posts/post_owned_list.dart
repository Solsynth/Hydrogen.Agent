import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/feed/feed_content.dart';
import 'package:solian/widgets/feed/feed_tags.dart';

class PostOwnedListEntry extends StatelessWidget {
  final Post item;
  final Function onTap;

  const PostOwnedListEntry({
    super.key,
    required this.item,
    required this.onTap,
  });

  Widget buildFooter(BuildContext context) {
    List<String> labels = List.empty(growable: true);
    if (item.createdAt == item.updatedAt) {
      labels.add('postNewCreated'.trParams({
        'date': DateFormat('yyyy/MM/dd HH:mm').format(item.updatedAt.toLocal()),
      }));
    } else {
      labels.add('postEdited'.trParams({
        'date': DateFormat('yyyy/MM/dd HH:mm').format(item.updatedAt.toLocal()),
      }));
    }
    if (item.realm != null) {
      labels.add('postInRealm'.trParams({
        'realm': '#${item.realm!.alias}',
      }));
    }

    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

    List<Widget> widgets = List.from([
      Row(
        children: [
          Text(
            'post'.tr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          Icon(Icons.text_snippet, size: 14, color: color).paddingOnly(left: 4),
        ],
      ),
    ], growable: true);

    if (item.tags?.isNotEmpty ?? false) {
      widgets.add(FeedTagsList(tags: item.tags!));
    }
    if (labels.isNotEmpty) {
      widgets.add(Text(
        labels.join(' · '),
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeedContent(content: item.content).paddingOnly(
              left: 12,
              right: 12,
              top: 8,
            ),
            buildFooter(context).paddingOnly(left: 12, top: 6, bottom: 8),
          ],
        ),
        onTap: () => onTap(),
      ),
    );
  }
}
