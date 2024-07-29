import 'package:solian/models/account.dart';

class Attachment {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String uuid;
  int size;
  String name;
  String alt;
  String usage;
  String mimetype;
  String hash;
  int destination;
  bool isAnalyzed;
  Map<String, dynamic>? metadata;
  bool isMature;
  Account? account;
  int? accountId;

  Attachment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.uuid,
    required this.size,
    required this.name,
    required this.alt,
    required this.usage,
    required this.mimetype,
    required this.hash,
    required this.destination,
    required this.isAnalyzed,
    required this.metadata,
    required this.isMature,
    required this.account,
    required this.accountId,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    uuid: json['uuid'],
    size: json['size'],
    name: json['name'],
    alt: json['alt'],
    usage: json['usage'],
    mimetype: json['mimetype'],
    hash: json['hash'],
    destination: json['destination'],
    isAnalyzed: json['is_analyzed'],
    metadata: json['metadata'],
    isMature: json['is_mature'],
    account: json['account'] != null ? Account.fromJson(json['account']) : null,
    accountId: json['account_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'uuid': uuid,
    'size': size,
    'name': name,
    'alt': alt,
    'usage': usage,
    'mimetype': mimetype,
    'hash': hash,
    'destination': destination,
    'is_analyzed': isAnalyzed,
    'metadata': metadata,
    'is_mature': isMature,
    'account': account?.toJson(),
    'account_id': accountId,
  };
}