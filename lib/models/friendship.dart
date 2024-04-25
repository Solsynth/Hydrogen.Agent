import 'package:solian/models/account.dart';

class Friendship {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int accountId;
  int relatedId;
  int? blockedBy;
  Account account;
  Account related;
  int status;

  Friendship({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.accountId,
    required this.relatedId,
    this.blockedBy,
    required this.account,
    required this.related,
    required this.status,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json["id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"],
    accountId: json["account_id"],
    relatedId: json["related_id"],
    blockedBy: json["blocked_by"],
    account: Account.fromJson(json["account"]),
    related: Account.fromJson(json["related"]),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "deleted_at": deletedAt,
    "account_id": accountId,
    "related_id": relatedId,
    "blocked_by": blockedBy,
    "account": account.toJson(),
    "related": related.toJson(),
    "status": status,
  };
}