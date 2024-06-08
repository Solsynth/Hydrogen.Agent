class Notification {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String subject;
  String content;
  List<Link>? links;
  DateTime? readAt;
  int? senderId;
  int recipientId;

  Notification({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.subject,
    required this.content,
    required this.links,
    required this.readAt,
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
        subject: json['subject'],
        content: json['content'],
        links: json['links'] != null
            ? List<Link>.from(json['links'].map((x) => Link.fromJson(x)))
            : List.empty(),
        readAt: json['read_at'],
        senderId: json['sender_id'],
        recipientId: json['recipient_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'subject': subject,
        'content': content,
        'links': links != null
            ? List<dynamic>.from(links!.map((x) => x.toJson()))
            : List.empty(),
        'read_at': readAt,
        'sender_id': senderId,
        'recipient_id': recipientId,
      };
}

class Link {
  String label;
  String url;

  Link({
    required this.label,
    required this.url,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        label: json['label'],
        url: json['url'],
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
      };
}
