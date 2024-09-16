// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      followerId: (json['follower_id'] as num).toInt(),
      follower: Account.fromJson(json['follower'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num?)?.toInt(),
      account: json['account'] == null
          ? null
          : Account.fromJson(json['account'] as Map<String, dynamic>),
      tagId: (json['tag_id'] as num?)?.toInt(),
      tag: json['tag'] == null
          ? null
          : Tag.fromJson(json['tag'] as Map<String, dynamic>),
      categoryId: (json['category_id'] as num?)?.toInt(),
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'follower_id': instance.followerId,
      'follower': instance.follower.toJson(),
      'account_id': instance.accountId,
      'account': instance.account?.toJson(),
      'tag_id': instance.tagId,
      'tag': instance.tag?.toJson(),
      'category_id': instance.categoryId,
      'category': instance.category?.toJson(),
    };
