import 'package:solian/models/channel.dart';

class Call {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? endedAt;
  String externalId;
  int founderId;
  int channelId;
  Channel channel;

  Call({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.endedAt,
    required this.externalId,
    required this.founderId,
    required this.channelId,
    required this.channel,
  });

  factory Call.fromJson(Map<String, dynamic> json) => Call(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        endedAt:
            json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
        externalId: json['external_id'],
        founderId: json['founder_id'],
        channelId: json['channel_id'],
        channel: Channel.fromJson(json['channel']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'ended_at': endedAt?.toIso8601String(),
        'external_id': externalId,
        'founder_id': founderId,
        'channel_id': channelId,
        'channel': channel.toJson(),
      };
}
