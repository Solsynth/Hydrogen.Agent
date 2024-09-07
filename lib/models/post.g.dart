// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.parse(json['edited_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      alias: json['alias'] as String?,
      areaAlias: json['area_alias'] as String?,
      type: json['type'] as String,
      body: json['body'],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      replyId: (json['reply_id'] as num?)?.toInt(),
      repostId: (json['repost_id'] as num?)?.toInt(),
      realmId: (json['realm_id'] as num?)?.toInt(),
      replyTo: json['reply_to'] == null
          ? null
          : Post.fromJson(json['reply_to'] as Map<String, dynamic>),
      repostTo: json['repost_to'] == null
          ? null
          : Post.fromJson(json['repost_to'] as Map<String, dynamic>),
      realm: json['realm'] == null
          ? null
          : Realm.fromJson(json['realm'] as Map<String, dynamic>),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      publishedUntil: json['published_until'] == null
          ? null
          : DateTime.parse(json['published_until'] as String),
      pinnedAt: json['pinned_at'] == null
          ? null
          : DateTime.parse(json['pinned_at'] as String),
      isDraft: json['is_draft'] as bool?,
      authorId: (json['author_id'] as num).toInt(),
      author: Account.fromJson(json['author'] as Map<String, dynamic>),
      metric: json['metric'] == null
          ? null
          : PostMetric.fromJson(json['metric'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'edited_at': instance.editedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'alias': instance.alias,
      'area_alias': instance.areaAlias,
      'body': instance.body,
      'tags': instance.tags?.map((e) => e.toJson()).toList(),
      'categories': instance.categories?.map((e) => e.toJson()).toList(),
      'replies': instance.replies?.map((e) => e.toJson()).toList(),
      'type': instance.type,
      'reply_id': instance.replyId,
      'repost_id': instance.repostId,
      'realm_id': instance.realmId,
      'reply_to': instance.replyTo?.toJson(),
      'repost_to': instance.repostTo?.toJson(),
      'realm': instance.realm?.toJson(),
      'published_at': instance.publishedAt?.toIso8601String(),
      'published_until': instance.publishedUntil?.toIso8601String(),
      'pinned_at': instance.pinnedAt?.toIso8601String(),
      'is_draft': instance.isDraft,
      'author_id': instance.authorId,
      'author': instance.author.toJson(),
      'metric': instance.metric?.toJson(),
    };

PostMetric _$PostMetricFromJson(Map<String, dynamic> json) => PostMetric(
      reactionCount: (json['reaction_count'] as num).toInt(),
      reactionList: (json['reaction_list'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          {},
      replyCount: (json['reply_count'] as num).toInt(),
    );

Map<String, dynamic> _$PostMetricToJson(PostMetric instance) =>
    <String, dynamic>{
      'reaction_count': instance.reactionCount,
      'reaction_list': instance.reactionList,
      'reply_count': instance.replyCount,
    };
