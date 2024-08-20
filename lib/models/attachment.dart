import 'package:solian/models/account.dart';

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
      AttachmentPlaceholder(
        chunkCount: json['chunk_count'],
        chunkSize: json['chunk_size'],
        meta: Attachment.fromJson(json['meta']),
      );

  Map<String, dynamic> toJson() => {
        'chunk_count': chunkCount,
        'chunk_size': chunkSize,
        'meta': meta.toJson(),
      };
}

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

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        rid: json['rid'],
        uuid: json['uuid'],
        size: json['size'],
        name: json['name'],
        alt: json['alt'],
        mimetype: json['mimetype'],
        hash: json['hash'],
        destination: json['destination'],
        isAnalyzed: json['is_analyzed'],
        isUploaded: json['is_uploaded'],
        metadata: json['metadata'],
        fileChunks: json['file_chunks'],
        isMature: json['is_mature'],
        account:
            json['account'] != null ? Account.fromJson(json['account']) : null,
        accountId: json['account_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'rid': rid,
        'uuid': uuid,
        'size': size,
        'name': name,
        'alt': alt,
        'mimetype': mimetype,
        'hash': hash,
        'destination': destination,
        'is_analyzed': isAnalyzed,
        'is_uploaded': isUploaded,
        'metadata': metadata,
        'file_chunks': fileChunks,
        'is_mature': isMature,
        'account': account?.toJson(),
        'account_id': accountId,
      };
}
