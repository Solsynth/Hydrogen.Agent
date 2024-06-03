import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/account.dart';

class AccountBadgeWidget extends StatefulWidget {
  final AccountBadge item;

  const AccountBadgeWidget({super.key, required this.item});

  @override
  State<AccountBadgeWidget> createState() => _AccountBadgeWidgetState();
}

class _AccountBadgeWidgetState extends State<AccountBadgeWidget> {
  final Map<String, (String, Widget)> badges = {
    'solsynth.staff': (
      'badgeSolsynthStaff'.tr,
      const FaIcon(
        FontAwesomeIcons.screwdriverWrench,
        size: 16,
        color: Colors.teal,
      ),
    ),
    'solar.originalCitizen': (
      'badgeSolarOriginalCitizen'.tr,
      const FaIcon(
        FontAwesomeIcons.tent,
        size: 16,
        color: Colors.orange,
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = badges[widget.item.type];

    if (spec == null) return const SizedBox();

    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(text: '${spec.$1}\n'),
          if (widget.item.metadata?['title'] != null)
            TextSpan(
              text: '${widget.item.metadata?['title']}\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          TextSpan(
            text: 'badgeGrantAt'.trParams(
                {'date': DateFormat.yMEd().format(widget.item.createdAt)}),
          ),
        ],
      ),
      child: Chip(
        label: spec.$2,
      ),
    );
  }
}
