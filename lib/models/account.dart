class Account {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? confirmedAt;
  DateTime? suspendedAt;
  String name;
  String nick;
  dynamic avatar;
  dynamic banner;
  String description;
  List<AccountBadge>? badges;
  String? emailAddress;
  int? externalId;

  Account({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.confirmedAt,
    required this.suspendedAt,
    required this.name,
    required this.nick,
    required this.avatar,
    required this.banner,
    required this.description,
    required this.badges,
    required this.emailAddress,
    this.externalId,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        confirmedAt: json['confirmed_at'] != null
            ? DateTime.parse(json['confirmed_at'])
            : null,
        suspendedAt: json['suspended_at'] != null
            ? DateTime.parse(json['suspended_at'])
            : null,
        name: json['name'],
        nick: json['nick'],
        avatar: json['avatar'],
        banner: json['banner'],
        description: json['description'],
        emailAddress: json['email_address'],
        badges: json['badges']
            ?.map((e) => AccountBadge.fromJson(e))
            .toList()
            .cast<AccountBadge>(),
        externalId: json['external_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'suspended_at': suspendedAt?.toIso8601String(),
        'name': name,
        'nick': nick,
        'avatar': avatar,
        'banner': banner,
        'description': description,
        'email_address': emailAddress,
        'badges': badges?.map((e) => e.toJson()).toList(),
        'external_id': externalId,
      };
}

class AccountBadge {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Map<String, dynamic>? metadata;
  String type;
  int accountId;

  AccountBadge({
    required this.id,
    required this.accountId,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.metadata,
    required this.type,
  });

  factory AccountBadge.fromJson(Map<String, dynamic> json) => AccountBadge(
        id: json['id'],
        accountId: json['account_id'],
        updatedAt: DateTime.parse(json['updated_at']),
        createdAt: DateTime.parse(json['created_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        metadata: json['metadata'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'metadata': metadata,
        'type': type,
      };
}
