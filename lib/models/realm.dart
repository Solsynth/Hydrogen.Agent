import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';

part 'realm.g.dart';

@JsonSerializable()
class Realm {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  String? avatar;
  String? banner;
  bool isPublic;
  bool isCommunity;
  int? accountId;
  int? externalId;

  Realm({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    required this.avatar,
    required this.banner,
    required this.isPublic,
    required this.isCommunity,
    this.accountId,
    this.externalId,
  });

  factory Realm.fromJson(Map<String, dynamic> json) => _$RealmFromJson(json);

  Map<String, dynamic> toJson() => _$RealmToJson(this);

  @override
  bool operator ==(Object other) {
    if (other is Realm) {
      return other.id == id;
    }
    return false;
  }

  @override
  int get hashCode => id;
}

@JsonSerializable()
class RealmMember {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int realmId;
  int accountId;
  Account account;
  int powerLevel;

  RealmMember({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.realmId,
    required this.accountId,
    required this.account,
    required this.powerLevel,
  });

  factory RealmMember.fromJson(Map<String, dynamic> json) =>
      _$RealmMemberFromJson(json);

  Map<String, dynamic> toJson() => _$RealmMemberToJson(this);
}
