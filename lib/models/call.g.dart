// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Call _$CallFromJson(Map<String, dynamic> json) => Call(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      externalId: json['external_id'] as String,
      founderId: (json['founder_id'] as num).toInt(),
      channelId: (json['channel_id'] as num).toInt(),
      participants: json['participants'] as List<dynamic>? ?? [],
      channel: Channel.fromJson(json['channel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CallToJson(Call instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'external_id': instance.externalId,
      'founder_id': instance.founderId,
      'channel_id': instance.channelId,
      'participants': instance.participants,
      'channel': instance.channel.toJson(),
    };
