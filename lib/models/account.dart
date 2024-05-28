class Account {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String name;
  String nick;
  dynamic avatar;
  dynamic banner;
  String description;
  String? emailAddress;
  int? externalId;

  Account({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.name,
    required this.nick,
    required this.avatar,
    required this.banner,
    required this.description,
    required this.emailAddress,
    this.externalId,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        name: json['name'],
        nick: json['nick'],
        avatar: json['avatar'],
        banner: json['banner'],
        description: json['description'],
        emailAddress: json['email_address'],
        externalId: json['external_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'name': name,
        'nick': nick,
        'avatar': avatar,
        'banner': banner,
        'description': description,
        'email_address': emailAddress,
        'external_id': externalId,
      };
}
