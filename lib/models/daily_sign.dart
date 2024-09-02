import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:solian/models/account.dart';

part 'daily_sign.g.dart';

@JsonSerializable()
class DailySignRecord {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Account account;
  int resultTier;
  int resultExperience;
  int accountId;

  DailySignRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.resultTier,
    required this.resultExperience,
    required this.account,
    required this.accountId,
  });

  factory DailySignRecord.fromJson(Map<String, dynamic> json) =>
      _$DailySignRecordFromJson(json);

  Map<String, dynamic> toJson() => _$DailySignRecordToJson(this);

  String get symbol => switch (resultTier) {
        0 => '大\n凶',
        1 => '凶',
        2 => '中\n平',
        3 => '吉',
        _ => '大\n吉',
      };

  String get overviewSuggestion => switch (resultTier) {
        0 => '诸事不宜',
        1 => '有些不宜',
        2 => '平平淡淡',
        3 => '有些事宜',
        _ => '诸事皆宜',
      };
}
