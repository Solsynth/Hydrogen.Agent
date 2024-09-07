import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_status.g.dart';

@JsonSerializable()
class AccountStatus {
  bool isDisturbable;
  bool isOnline;
  DateTime? lastSeenAt;
  Status? status;

  AccountStatus({
    required this.isDisturbable,
    required this.isOnline,
    required this.lastSeenAt,
    required this.status,
  });

  factory AccountStatus.fromJson(Map<String, dynamic> json) =>
      _$AccountStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AccountStatusToJson(this);
}

@JsonSerializable()
class Status {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String type;
  String label;
  int attitude;
  bool isNoDisturb;
  bool isInvisible;
  DateTime? clearAt;
  int accountId;

  Status({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.type,
    required this.label,
    required this.attitude,
    required this.isNoDisturb,
    required this.isInvisible,
    required this.clearAt,
    required this.accountId,
  });

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}
