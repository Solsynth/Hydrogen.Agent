import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/channel.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  int id;
  String uuid;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Map<String, dynamic> body;
  String type;
  Channel? channel;
  ChannelMember sender;
  int channelId;
  int senderId;

  @JsonKey(includeFromJson: false, includeToJson: true)
  bool isPending = false;

  Event({
    required this.id,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.body,
    required this.type,
    this.channel,
    required this.sender,
    required this.channelId,
    required this.senderId,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}

@JsonSerializable()
class EventMessageBody {
  @JsonKey(defaultValue: '')
  String text;
  @JsonKey(defaultValue: 'plain')
  String algorithm;
  List<String>? attachments;
  int? quoteEvent;
  int? relatedEvent;
  List<int>? relatedUsers;

  EventMessageBody({
    required this.text,
    required this.algorithm,
    required this.attachments,
    required this.quoteEvent,
    required this.relatedEvent,
    required this.relatedUsers,
  });

  factory EventMessageBody.fromJson(Map<String, dynamic> json) =>
      _$EventMessageBodyFromJson(json);

  Map<String, dynamic> toJson() => _$EventMessageBodyToJson(this);
}
