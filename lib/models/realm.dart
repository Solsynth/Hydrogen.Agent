class Realm {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  dynamic members;
  bool isPublic;
  bool isCommunity;
  int accountId;

  Realm({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    required this.members,
    required this.isPublic,
    required this.isCommunity,
    required this.accountId,
  });

  factory Realm.fromJson(Map<String, dynamic> json) => Realm(
    id: json['id'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    alias: json['alias'],
    name: json['name'],
    description: json['description'],
    members: json['members'],
    isPublic: json['is_public'],
    isCommunity: json['is_community'],
    accountId: json['account_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt,
    'alias': alias,
    'name': name,
    'description': description,
    'members': members,
    'is_public': isPublic,
    'is_community': isCommunity,
    'account_id': accountId,
  };
}