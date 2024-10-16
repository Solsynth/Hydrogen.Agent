import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart';

class RelativeDate extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;
  final bool isFull;

  const RelativeDate(this.date, {super.key, this.style, this.isFull = false});

  @override
  Widget build(BuildContext context) {
    if (isFull) {
      return Text(
        DateFormat('y/M/d HH:mm').format(date),
        style: style,
      );
    }
    return Text(
      format(
        date,
        locale: 'en_short',
      ),
      style: style,
    );
  }
}
