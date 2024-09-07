// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      body: json['body'] as String,
      avatar: json['avatar'] as String?,
      picture: json['picture'] as String?,
      senderId: (json['sender_id'] as num?)?.toInt(),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'title': instance.title,
      'subtitle': instance.subtitle,
      'body': instance.body,
      'avatar': instance.avatar,
      'picture': instance.picture,
      'sender_id': instance.senderId,
      'account_id': instance.accountId,
    };
