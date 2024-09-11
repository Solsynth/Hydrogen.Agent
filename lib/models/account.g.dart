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
      profile: json['profile'] == null
          ? null
          : AccountProfile.fromJson(json['profile'] as Map<String, dynamic>),
      badges: (json['badges'] as List<dynamic>?)
          ?.map((e) => AccountBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      emailAddress: json['email_address'] as String?,
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
      'profile': instance.profile?.toJson(),
      'badges': instance.badges?.map((e) => e.toJson()).toList(),
      'email_address': instance.emailAddress,
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

AccountProfile _$AccountProfileFromJson(Map<String, dynamic> json) =>
    AccountProfile(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      experience: (json['experience'] as num?)?.toInt(),
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      birthday: json['birthday'] == null
          ? null
          : DateTime.parse(json['birthday'] as String),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$AccountProfileToJson(AccountProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'experience': instance.experience,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'birthday': instance.birthday?.toIso8601String(),
      'account_id': instance.accountId,
    };
