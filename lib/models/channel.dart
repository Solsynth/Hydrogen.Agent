class Channel {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  dynamic members;
  dynamic messages;
  dynamic calls;
  int type;
  int accountId;
  int realmId;

  Channel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    this.members,
    this.messages,
    this.calls,
    required this.type,
    required this.accountId,
    required this.realmId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json["id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"],
    alias: json["alias"],
    name: json["name"],
    description: json["description"],
    members: json["members"],
    messages: json["messages"],
    calls: json["calls"],
    type: json["type"],
    accountId: json["account_id"],
    realmId: json["realm_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "deleted_at": deletedAt,
    "alias": alias,
    "name": name,
    "description": description,
    "members": members,
    "messages": messages,
    "calls": calls,
    "type": type,
    "account_id": accountId,
    "realm_id": realmId,
  };
}