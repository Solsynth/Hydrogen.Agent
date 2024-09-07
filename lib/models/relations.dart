import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:solian/models/account.dart';

part 'relations.g.dart';

@JsonSerializable()
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

  factory Relationship.fromJson(Map<String, dynamic> json) =>
      _$RelationshipFromJson(json);

  Map<String, dynamic> toJson() => _$RelationshipToJson(this);
}
