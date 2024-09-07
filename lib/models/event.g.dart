// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      body: json['body'] as Map<String, dynamic>,
      type: json['type'] as String,
      channel: json['channel'] == null
          ? null
          : Channel.fromJson(json['channel'] as Map<String, dynamic>),
      sender: ChannelMember.fromJson(json['sender'] as Map<String, dynamic>),
      channelId: (json['channel_id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
    );

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'body': instance.body,
      'type': instance.type,
      'channel': instance.channel?.toJson(),
      'sender': instance.sender.toJson(),
      'channel_id': instance.channelId,
      'sender_id': instance.senderId,
      'is_pending': instance.isPending,
    };

EventMessageBody _$EventMessageBodyFromJson(Map<String, dynamic> json) =>
    EventMessageBody(
      text: json['text'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'plain',
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      quoteEvent: (json['quote_event'] as num?)?.toInt(),
      relatedEvent: (json['related_event'] as num?)?.toInt(),
      relatedUsers: (json['related_users'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$EventMessageBodyToJson(EventMessageBody instance) =>
    <String, dynamic>{
      'text': instance.text,
      'algorithm': instance.algorithm,
      'attachments': instance.attachments,
      'quote_event': instance.quoteEvent,
      'related_event': instance.relatedEvent,
      'related_users': instance.relatedUsers,
    };
