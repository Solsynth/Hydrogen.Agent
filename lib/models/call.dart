import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:solian/models/channel.dart';

part 'call.g.dart';

@JsonSerializable()
class Call {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? endedAt;
  String externalId;
  int founderId;
  int channelId;
  @JsonKey(defaultValue: [])
  List<dynamic>? participants;
  Channel channel;

  Call({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.endedAt,
    required this.externalId,
    required this.founderId,
    required this.channelId,
    required this.participants,
    required this.channel,
  });

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);

  Map<String, dynamic> toJson() => _$CallToJson(this);
}

enum ParticipantStatsType {
  unknown,
  localAudioSender,
  localVideoSender,
  remoteAudioReceiver,
  remoteVideoReceiver,
}

class ParticipantTrack {
  ParticipantTrack(
      {required this.participant,
      required this.videoTrack,
      required this.isScreenShare});

  VideoTrack? videoTrack;
  Participant participant;
  bool isScreenShare;
}
