class Notification {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String title;
  String? subtitle;
  String body;
  String? avatar;
  String? picture;
  int? senderId;
  int recipientId;

  Notification({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.avatar,
    required this.picture,
    required this.senderId,
    required this.recipientId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'] ?? 0,
        createdAt: json['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] == null
            ? DateTime.now()
            : DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        title: json['title'],
        subtitle: json['subtitle'],
        body: json['body'],
        avatar: json['avatar'],
        picture: json['picture'],
        senderId: json['sender_id'],
        recipientId: json['recipient_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'title': title,
        'subtitle': subtitle,
        'body': body,
        'avatar': avatar,
        'picture': picture,
        'sender_id': senderId,
        'recipient_id': recipientId,
      };
}
