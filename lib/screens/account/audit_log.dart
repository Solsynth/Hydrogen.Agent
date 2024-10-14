import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
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

  final List<AuditEvent> _events = List.empty(growable: true);

  Future<void> _getEvents() async {
    if (!_isBusy) setState(() => _isBusy = true);

    final AuthProvider auth = Get.find();
    final client = await auth.configureClient('id');
    final resp =
        await client.get('/users/me/events?take=15&offset=${_events.length}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(RequestException(resp));
    }

    final result = PaginationResult.fromJson(resp.body);

    setState(() {
      _events.addAll(
        result.data?.map((x) => AuditEvent.fromJson(x)).toList() ??
            List.empty(),
      );
      _isBusy = false;
    });
  }

  bool _showIp = false;

  String _censorIpAddress(String ip) {
    List<String> parts = ip.split('.');

    if (parts.length == 4) {
      String censoredPart1 = '*' * parts[1].length;
      String censoredPart2 = '*' * parts[2].length;
      String censoredPart3 = '*' * parts[3].length;

      return '${parts[0]}.$censoredPart1.$censoredPart2.$censoredPart3';
    } else {
      return '***.***.***.***';
    }
  }

  @override
  void initState() {
    super.initState();
    _getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          value: _showIp,
          title: Text('showIp'.tr),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          secondary: const Icon(Icons.alternate_email),
          tileColor:
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
          onChanged: (val) {
            setState(() => _showIp = val ?? false);
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () {
              _events.clear();
              return _getEvents();
            },
            child: InfiniteList(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                  indicatorStyle: IndicatorStyle(width: 15),
                  endChild: Container(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            element.type,
                            style: GoogleFonts.robotoMono(fontSize: 15),
                          ),
                          Text(
                            _showIp
                                ? element.ipAddress
                                : _censorIpAddress(element.ipAddress),
                            style: GoogleFonts.sourceCodePro(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: double.maxFinite,
                            child: Marquee(
                              text: element.userAgent,
                              velocity: 25,
                              startAfter: Duration(milliseconds: 500),
                              pauseAfterRound: Duration(milliseconds: 3000),
                            ),
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
            ),
          ),
        ),
      ],
    );
  }
}
