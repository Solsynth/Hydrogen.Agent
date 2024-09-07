// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stickers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sticker _$StickerFromJson(Map<String, dynamic> json) => Sticker(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      alias: json['alias'] as String,
      name: json['name'] as String,
      attachmentId: (json['attachment_id'] as num).toInt(),
      attachment:
          Attachment.fromJson(json['attachment'] as Map<String, dynamic>),
      packId: (json['pack_id'] as num).toInt(),
      pack: json['pack'] == null
          ? null
          : StickerPack.fromJson(json['pack'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StickerToJson(Sticker instance) => <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'alias': instance.alias,
      'name': instance.name,
      'attachment_id': instance.attachmentId,
      'attachment': instance.attachment.toJson(),
      'pack_id': instance.packId,
      'pack': instance.pack?.toJson(),
      'account_id': instance.accountId,
      'account': instance.account.toJson(),
    };

StickerPack _$StickerPackFromJson(Map<String, dynamic> json) => StickerPack(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      prefix: json['prefix'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      stickers: (json['stickers'] as List<dynamic>?)
          ?.map((e) => Sticker.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountId: (json['account_id'] as num).toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StickerPackToJson(StickerPack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'prefix': instance.prefix,
      'name': instance.name,
      'description': instance.description,
      'stickers': instance.stickers?.map((e) => e.toJson()).toList(),
      'account_id': instance.accountId,
      'account': instance.account.toJson(),
    };
