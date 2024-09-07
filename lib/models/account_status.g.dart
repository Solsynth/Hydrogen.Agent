// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountStatus _$AccountStatusFromJson(Map<String, dynamic> json) =>
    AccountStatus(
      isDisturbable: json['is_disturbable'] as bool,
      isOnline: json['is_online'] as bool,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      status: json['status'] == null
          ? null
          : Status.fromJson(json['status'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AccountStatusToJson(AccountStatus instance) =>
    <String, dynamic>{
      'is_disturbable': instance.isDisturbable,
      'is_online': instance.isOnline,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'status': instance.status?.toJson(),
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      type: json['type'] as String,
      label: json['label'] as String,
      attitude: (json['attitude'] as num).toInt(),
      isNoDisturb: json['is_no_disturb'] as bool,
      isInvisible: json['is_invisible'] as bool,
      clearAt: json['clear_at'] == null
          ? null
          : DateTime.parse(json['clear_at'] as String),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'type': instance.type,
      'label': instance.label,
      'attitude': instance.attitude,
      'is_no_disturb': instance.isNoDisturb,
      'is_invisible': instance.isInvisible,
      'clear_at': instance.clearAt?.toIso8601String(),
      'account_id': instance.accountId,
    };
