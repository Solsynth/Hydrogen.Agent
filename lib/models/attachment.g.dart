// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentPlaceholder _$AttachmentPlaceholderFromJson(
        Map<String, dynamic> json) =>
    AttachmentPlaceholder(
      chunkCount: (json['chunk_count'] as num).toInt(),
      chunkSize: (json['chunk_size'] as num).toInt(),
      meta: Attachment.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentPlaceholderToJson(
        AttachmentPlaceholder instance) =>
    <String, dynamic>{
      'chunk_count': instance.chunkCount,
      'chunk_size': instance.chunkSize,
      'meta': instance.meta.toJson(),
    };

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      rid: json['rid'] as String,
      uuid: json['uuid'] as String,
      size: (json['size'] as num).toInt(),
      name: json['name'] as String,
      alt: json['alt'] as String,
      mimetype: json['mimetype'] as String,
      hash: json['hash'] as String,
      destination: (json['destination'] as num).toInt(),
      isAnalyzed: json['is_analyzed'] as bool,
      isUploaded: json['is_uploaded'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
      fileChunks: json['file_chunks'] as Map<String, dynamic>?,
      isMature: json['is_mature'] as bool,
      account: json['account'] == null
          ? null
          : Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'rid': instance.rid,
      'uuid': instance.uuid,
      'size': instance.size,
      'name': instance.name,
      'alt': instance.alt,
      'mimetype': instance.mimetype,
      'hash': instance.hash,
      'destination': instance.destination,
      'is_analyzed': instance.isAnalyzed,
      'is_uploaded': instance.isUploaded,
      'metadata': instance.metadata,
      'file_chunks': instance.fileChunks,
      'is_mature': instance.isMature,
      'account': instance.account?.toJson(),
      'account_id': instance.accountId,
    };
