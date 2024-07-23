class Tag {
  int id;
  String alias;
  String name;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  Tag({
    required this.id,
    required this.alias,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        alias: json['alias'],
        name: json['name'],
        description: json['description'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'description': description,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}

class Category {
  int id;
  String alias;
  String name;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  Category({
    required this.id,
    required this.alias,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        alias: json['alias'],
        name: json['name'],
        description: json['description'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'description': description,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}
