import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? confirmedAt;
  DateTime? suspendedAt;
  String name;
  String nick;
  dynamic avatar;
  dynamic banner;
  String description;
  AccountProfile? profile;
  List<AccountBadge>? badges;
  String? emailAddress;

  Account({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.confirmedAt,
    required this.suspendedAt,
    required this.name,
    required this.nick,
    required this.avatar,
    required this.banner,
    required this.description,
    required this.profile,
    required this.badges,
    required this.emailAddress,
  });

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
}

@JsonSerializable()
class AccountBadge {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Map<String, dynamic>? metadata;
  String type;
  int accountId;

  AccountBadge({
    required this.id,
    required this.accountId,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.metadata,
    required this.type,
  });

  factory AccountBadge.fromJson(Map<String, dynamic> json) =>
      _$AccountBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$AccountBadgeToJson(this);
}

@JsonSerializable()
class AccountProfile {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String? firstName;
  String? lastName;
  int? experience;
  DateTime? lastSeenAt;
  DateTime? birthday;
  int accountId;

  AccountProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.firstName,
    required this.lastName,
    required this.experience,
    required this.lastSeenAt,
    required this.birthday,
    required this.accountId,
  });

  factory AccountProfile.fromJson(Map<String, dynamic> json) =>
      _$AccountProfileFromJson(json);

  Map<String, dynamic> toJson() => _$AccountProfileToJson(this);
}
