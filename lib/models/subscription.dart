import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/post_categories.dart';

part 'subscription.g.dart';

@JsonSerializable()
class Subscription {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int followerId;
  Account follower;
  int? accountId;
  Account? account;
  int? tagId;
  Tag? tag;
  int? categoryId;
  Category? category;

  Subscription({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.followerId,
    required this.follower,
    required this.accountId,
    required this.account,
    required this.tagId,
    required this.tag,
    required this.categoryId,
    required this.category,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}
