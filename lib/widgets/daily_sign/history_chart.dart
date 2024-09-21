import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/daily_sign.dart';

class DailySignHistoryChartDialog extends StatelessWidget {
  final List<DailySignRecord>? data;

  const DailySignHistoryChartDialog({super.key, required this.data});

  static final List<String> signSymbols = ['大凶', '凶', '中平', '吉', '大吉'];

  DateTime? get _firstRecordDate => data?.map((x) => x.createdAt).reduce(
      (a, b) => DateTime.fromMillisecondsSinceEpoch(
          min(a.millisecondsSinceEpoch, b.millisecondsSinceEpoch)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('dailySignHistoryTitle'.tr),
          Text(
            '${DateFormat('yyyy/MM/dd').format(_firstRecordDate!)} - ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
      content: data == null
          ? SizedBox(
              height: 180,
              width: max(640, MediaQuery.of(context).size.width),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dailySignHistoryRecent'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ).paddingOnly(bottom: 18),
                SizedBox(
                  height: 180,
                  width: max(640, MediaQuery.of(context).size.width),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          color: Theme.of(context).colorScheme.primary,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: List.filled(
                                data!.length,
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ).toList(),
                            ),
                          ),
                          spots: data!
                              .map(
                                (x) => FlSpot(
                                  x.createdAt
                                      .copyWith(
                                        hour: 0,
                                        minute: 0,
                                        second: 0,
                                        millisecond: 0,
                                        microsecond: 0,
                                      )
                                      .millisecondsSinceEpoch
                                      .toDouble(),
                                  x.resultTier.toDouble(),
                                ),
                              )
                              .toList(),
                        )
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots
                              .map((spot) => LineTooltipItem(
                                    '${signSymbols[spot.y.toInt()]}\n${DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                                    TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ))
                              .toList(),
                          getTooltipColor: (_) => Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: (value, _) => Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                signSymbols[value.toInt()],
                                textAlign: TextAlign.right,
                              ).paddingOnly(right: 8),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 86400000,
                            getTitlesWidget: (value, _) => Text(
                              DateFormat('dd').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt(),
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ).paddingOnly(top: 8),
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ).marginOnly(right: 24, bottom: 8, top: 8),
                const Gap(16),
                Text(
                  'dailySignHistoryReward'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ).paddingOnly(bottom: 18),
                SizedBox(
                  height: 180,
                  width: max(640, MediaQuery.of(context).size.width),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          color: Theme.of(context).colorScheme.primary,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: List.filled(
                                data!.length,
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ).toList(),
                            ),
                          ),
                          spots: data!
                              .map(
                                (x) => FlSpot(
                                  x.createdAt
                                      .copyWith(
                                        hour: 0,
                                        minute: 0,
                                        second: 0,
                                        millisecond: 0,
                                        microsecond: 0,
                                      )
                                      .millisecondsSinceEpoch
                                      .toDouble(),
                                  x.resultExperience.toDouble(),
                                ),
                              )
                              .toList(),
                        )
                      ],
                      lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map((spot) => LineTooltipItem(
                                  '+${spot.y.toStringAsFixed(0)} EXP\n${DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                                  TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ))
                            .toList(),
                        getTooltipColor: (_) =>
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                      )),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                value.toStringAsFixed(0),
                                textAlign: TextAlign.right,
                              ).paddingOnly(right: 8),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 86400000,
                            getTitlesWidget: (value, _) => Text(
                              DateFormat('dd').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt(),
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ).paddingOnly(top: 8),
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ).marginOnly(right: 24, bottom: 8, top: 8),
              ],
            ),
    );
  }
}
