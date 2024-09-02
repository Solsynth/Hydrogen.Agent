// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_sign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailySignRecord _$DailySignRecordFromJson(Map<String, dynamic> json) =>
    DailySignRecord(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      resultTier: (json['result_tier'] as num).toInt(),
      resultExperience: (json['result_experience'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$DailySignRecordToJson(DailySignRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'account': instance.account.toJson(),
      'result_tier': instance.resultTier,
      'result_experience': instance.resultExperience,
      'account_id': instance.accountId,
    };
