// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Realm _$RealmFromJson(Map<String, dynamic> json) => Realm(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      alias: json['alias'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isPublic: json['is_public'] as bool,
      isCommunity: json['is_community'] as bool,
      accountId: (json['account_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RealmToJson(Realm instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'alias': instance.alias,
      'name': instance.name,
      'description': instance.description,
      'is_public': instance.isPublic,
      'is_community': instance.isCommunity,
      'account_id': instance.accountId,
    };

RealmMember _$RealmMemberFromJson(Map<String, dynamic> json) => RealmMember(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      realmId: (json['realm_id'] as num).toInt(),
      accountId: (json['account_id'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      powerLevel: (json['power_level'] as num).toInt(),
    );

Map<String, dynamic> _$RealmMemberToJson(RealmMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'realm_id': instance.realmId,
      'account_id': instance.accountId,
      'account': instance.account.toJson(),
      'power_level': instance.powerLevel,
    };
