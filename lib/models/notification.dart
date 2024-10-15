import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? readAt;
  String title;
  String? subtitle;
  String body;
  String? avatar;
  String? picture;
  int? senderId;
  int accountId;

  Notification({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.readAt,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.avatar,
    required this.picture,
    required this.senderId,
    required this.accountId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}
