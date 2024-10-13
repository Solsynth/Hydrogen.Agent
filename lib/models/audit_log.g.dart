// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEvent _$AuditEventFromJson(Map<String, dynamic> json) => AuditEvent(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      type: json['type'] as String,
      target: json['target'] as String,
      location: json['location'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$AuditEventToJson(AuditEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'type': instance.type,
      'target': instance.target,
      'location': instance.location,
      'ip_address': instance.ipAddress,
      'user_agent': instance.userAgent,
      'account': instance.account.toJson(),
      'account_id': instance.accountId,
    };
