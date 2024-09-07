import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:solian/models/account.dart';

part 'attachment.g.dart';

@JsonSerializable()
class AttachmentPlaceholder {
  int chunkCount;
  int chunkSize;
  Attachment meta;

  AttachmentPlaceholder({
    required this.chunkCount,
    required this.chunkSize,
    required this.meta,
  });

  factory AttachmentPlaceholder.fromJson(Map<String, dynamic> json) =>
      _$AttachmentPlaceholderFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentPlaceholderToJson(this);
}

@JsonSerializable()
class Attachment {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String rid;
  String uuid;
  int size;
  String name;
  String alt;
  String mimetype;
  String hash;
  int destination;
  bool isAnalyzed;
  bool isUploaded;
  Map<String, dynamic>? metadata;
  Map<String, dynamic>? fileChunks;
  bool isMature;
  Account? account;
  int? accountId;

  Attachment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.rid,
    required this.uuid,
    required this.size,
    required this.name,
    required this.alt,
    required this.mimetype,
    required this.hash,
    required this.destination,
    required this.isAnalyzed,
    required this.isUploaded,
    required this.metadata,
    required this.fileChunks,
    required this.isMature,
    required this.account,
    required this.accountId,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
