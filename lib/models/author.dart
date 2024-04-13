class Author {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String name;
  String nick;
  String avatar;
  String banner;
  String description;
  String emailAddress;
  int powerLevel;
  int externalId;

  Author({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.nick,
    required this.avatar,
    required this.banner,
    required this.description,
    required this.emailAddress,
    required this.powerLevel,
    required this.externalId,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        name: json["name"],
        nick: json["nick"],
        avatar: json["avatar"],
        banner: json["banner"],
        description: json["description"],
        emailAddress: json["email_address"],
        powerLevel: json["power_level"],
        externalId: json["external_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "name": name,
        "nick": nick,
        "avatar": avatar,
        "banner": banner,
        "description": description,
        "email_address": emailAddress,
        "power_level": powerLevel,
        "external_id": externalId,
      };
}
