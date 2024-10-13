import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/audit_log.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/relative_date.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:timeline_tile/timeline_tile.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _isBusy = true;

  int _totalEvent = 0;
  List<AuditEvent> _events = List.empty(growable: true);

  Future<void> _getEvents() async {
    if (!_isBusy) setState(() => _isBusy = true);

    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('id');
    final resp =
        await client.get('/users/me/events?take=10&offset=${_events.length}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(RequestException(resp));
    }

    final result = PaginationResult.fromJson(resp.body);

    setState(() {
      _totalEvent = result.count;
      _events.addAll(
        result.data?.map((x) => AuditEvent.fromJson(x)).toList() ??
            List.empty(),
      );
      _isBusy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      itemCount: _events.length,
      isLoading: _isBusy,
      onFetchData: () {
        _getEvents();
      },
      itemBuilder: (context, idx) {
        final element = _events[idx];
        return TimelineTile(
          isFirst: idx == 0,
          isLast: _events.length - 1 == idx,
          alignment: TimelineAlign.start,
          endChild: Container(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.type,
                    style: GoogleFonts.robotoMono(fontSize: 15),
                  ),
                  Row(
                    children: [
                      RelativeDate(element.createdAt),
                      const Gap(6),
                      Text('·'),
                      const Gap(6),
                      RelativeDate(element.createdAt, isFull: true),
                    ],
                  ),
                ],
              ).paddingSymmetric(horizontal: 12, vertical: 8),
            ).paddingOnly(left: 16),
          ),
        ).paddingSymmetric(horizontal: 18);
      },
    );
  }
}
