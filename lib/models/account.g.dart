// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      suspendedAt: json['suspended_at'] == null
          ? null
          : DateTime.parse(json['suspended_at'] as String),
      name: json['name'] as String,
      nick: json['nick'] as String,
      avatar: json['avatar'],
      banner: json['banner'],
      description: json['description'] as String,
      badges: (json['badges'] as List<dynamic>?)
          ?.map((e) => AccountBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      emailAddress: json['email_address'] as String?,
      externalId: (json['external_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'suspended_at': instance.suspendedAt?.toIso8601String(),
      'name': instance.name,
      'nick': instance.nick,
      'avatar': instance.avatar,
      'banner': instance.banner,
      'description': instance.description,
      'badges': instance.badges?.map((e) => e.toJson()).toList(),
      'email_address': instance.emailAddress,
      'external_id': instance.externalId,
    };

AccountBadge _$AccountBadgeFromJson(Map<String, dynamic> json) => AccountBadge(
      id: (json['id'] as num).toInt(),
      accountId: (json['account_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AccountBadgeToJson(AccountBadge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'metadata': instance.metadata,
      'type': instance.type,
      'account_id': instance.accountId,
    };
