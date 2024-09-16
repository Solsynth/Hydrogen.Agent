import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/realm.dart';

part 'channel.g.dart';

@JsonSerializable()
class Channel {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  int type;
  List<ChannelMember>? members;
  Account account;
  int accountId;
  Realm? realm;
  int? realmId;
  bool isEncrypted;

  @JsonKey(includeFromJson: false, includeToJson: true)
  bool isAvailable = false;

  Channel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    required this.type,
    required this.members,
    required this.account,
    required this.accountId,
    required this.isEncrypted,
    required this.realm,
    required this.realmId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) =>
      _$ChannelFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelToJson(this);

  @override
  bool operator ==(Object other) {
    if (other is! Channel) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id;
}

@JsonSerializable()
class ChannelMember {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int channelId;
  int accountId;
  Account account;
  int notify;

  ChannelMember({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.channelId,
    required this.accountId,
    required this.account,
    required this.notify,
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) =>
      _$ChannelMemberFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelMemberToJson(this);
}
