import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.g.dart';

@JsonSerializable()
class LinkMeta {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String entryId;
  String? icon;
  String url;
  String? title;
  String? image;
  String? video;
  String? audio;
  String? description;
  String? siteName;

  LinkMeta({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.entryId,
    required this.icon,
    required this.url,
    required this.title,
    required this.image,
    required this.video,
    required this.audio,
    required this.description,
    required this.siteName,
  });

  factory LinkMeta.fromJson(Map<String, dynamic> json) =>
      _$LinkMetaFromJson(json);

  Map<String, dynamic> toJson() => _$LinkMetaToJson(this);
}
