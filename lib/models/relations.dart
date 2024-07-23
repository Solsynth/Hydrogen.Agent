import 'package:solian/models/account.dart';

class Relationship {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int accountId;
  int relatedId;
  Account account;
  Account related;
  int status;

  Relationship({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.accountId,
    required this.relatedId,
    required this.account,
    required this.related,
    required this.status,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        accountId: json['account_id'],
        relatedId: json['related_id'],
        account: Account.fromJson(json['account']),
        related: Account.fromJson(json['related']),
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'account_id': accountId,
        'related_id': relatedId,
        'account': account.toJson(),
        'related': related.toJson(),
        'status': status,
      };

  Account getOtherside(int selfId) {
    if (accountId != selfId) {
      return account;
    } else {
      return related;
    }
  }
}
