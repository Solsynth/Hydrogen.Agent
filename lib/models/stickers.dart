import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/services.dart';

part 'stickers.g.dart';

@JsonSerializable()
class Sticker {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  int attachmentId;
  Attachment attachment;
  int packId;
  StickerPack? pack;
  int accountId;
  Account account;

  Sticker({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.name,
    required this.attachmentId,
    required this.attachment,
    required this.packId,
    required this.pack,
    required this.accountId,
    required this.account,
  });

  String get textPlaceholder => '${pack?.prefix}$alias';
  String get textWarpedPlaceholder => ':$textPlaceholder:';

  String get imageUrl => ServiceFinder.buildUrl(
        'files',
        '/attachments/${attachment.rid}',
      );

  factory Sticker.fromJson(Map<String, dynamic> json) =>
      _$StickerFromJson(json);

  Map<String, dynamic> toJson() => _$StickerToJson(this);
}

@JsonSerializable()
class StickerPack {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String prefix;
  String name;
  String description;
  List<Sticker>? stickers;
  int accountId;
  Account account;

  StickerPack({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.prefix,
    required this.name,
    required this.description,
    required this.stickers,
    required this.accountId,
    required this.account,
  });

  factory StickerPack.fromJson(Map<String, dynamic> json) =>
      _$StickerPackFromJson(json);

  Map<String, dynamic> toJson() => _$StickerPackToJson(this);
}
