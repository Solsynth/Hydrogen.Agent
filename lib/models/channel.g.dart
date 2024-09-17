// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Channel _$ChannelFromJson(Map<String, dynamic> json) => Channel(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      alias: json['alias'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: (json['type'] as num).toInt(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ChannelMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
      isPublic: json['is_public'] as bool,
      isCommunity: json['is_community'] as bool,
      realm: json['realm'] == null
          ? null
          : Realm.fromJson(json['realm'] as Map<String, dynamic>),
      realmId: (json['realm_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'alias': instance.alias,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'members': instance.members?.map((e) => e.toJson()).toList(),
      'account': instance.account.toJson(),
      'account_id': instance.accountId,
      'realm': instance.realm?.toJson(),
      'realm_id': instance.realmId,
      'is_public': instance.isPublic,
      'is_community': instance.isCommunity,
      'is_available': instance.isAvailable,
    };

ChannelMember _$ChannelMemberFromJson(Map<String, dynamic> json) =>
    ChannelMember(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      channelId: (json['channel_id'] as num).toInt(),
      accountId: (json['account_id'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      notify: (json['notify'] as num).toInt(),
    );

Map<String, dynamic> _$ChannelMemberToJson(ChannelMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'channel_id': instance.channelId,
      'account_id': instance.accountId,
      'account': instance.account.toJson(),
      'notify': instance.notify,
    };
