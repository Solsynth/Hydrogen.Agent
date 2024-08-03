import 'package:solian/models/account.dart';
import 'package:solian/models/attachment.dart';

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

  factory Sticker.fromJson(Map<String, dynamic> json) => Sticker(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : json['deleted_at'],
        alias: json['alias'],
        name: json['name'],
        attachmentId: json['attachment_id'],
        attachment: Attachment.fromJson(json['attachment']),
        packId: json['pack_id'],
        pack: json['pack'] != null ? StickerPack.fromJson(json['pack']) : null,
        accountId: json['account_id'],
        account: Account.fromJson(json['account']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'alias': alias,
        'name': name,
        'attachment_id': attachmentId,
        'attachment': attachment.toJson(),
        'pack_id': packId,
        'account_id': accountId,
        'account': account.toJson(),
      };
}

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

  factory StickerPack.fromJson(Map<String, dynamic> json) => StickerPack(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : json['deleted_at'],
        prefix: json['prefix'],
        name: json['name'],
        description: json['description'],
        stickers: json['stickers'] == null
            ? []
            : List<Sticker>.from(
                json['stickers']!.map((x) => Sticker.fromJson(x))),
        accountId: json['account_id'],
        account: Account.fromJson(json['account']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'prefix': prefix,
        'name': name,
        'description': description,
        'stickers': stickers == null
            ? []
            : List<dynamic>.from(stickers!.map((x) => x.toJson())),
        'account_id': accountId,
        'account': account.toJson(),
      };
}
