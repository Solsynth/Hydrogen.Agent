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
  int accountId;

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
    required this.accountId,
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
        accountId: json['account_id'],
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
        'account_id': accountId,
      };
}
