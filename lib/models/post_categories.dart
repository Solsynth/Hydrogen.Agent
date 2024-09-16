import 'package:json_annotation/json_annotation.dart';

part 'post_categories.g.dart';

@JsonSerializable()
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

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}

@JsonSerializable()
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

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
