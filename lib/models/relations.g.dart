// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Relationship _$RelationshipFromJson(Map<String, dynamic> json) => Relationship(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      accountId: (json['account_id'] as num).toInt(),
      relatedId: (json['related_id'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      related: Account.fromJson(json['related'] as Map<String, dynamic>),
      status: (json['status'] as num).toInt(),
    );

Map<String, dynamic> _$RelationshipToJson(Relationship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'account_id': instance.accountId,
      'related_id': instance.relatedId,
      'account': instance.account.toJson(),
      'related': instance.related.toJson(),
      'status': instance.status,
    };
