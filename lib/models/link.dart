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

  factory LinkMeta.fromJson(Map<String, dynamic> json) => LinkMeta(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        entryId: json['entry_id'],
        icon: json['icon'],
        url: json['url'],
        title: json['title'],
        image: json['image'],
        video: json['video'],
        audio: json['audio'],
        description: json['description'],
        siteName: json['site_name'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'entry_id': entryId,
        'icon': icon,
        'url': url,
        'title': title,
        'image': image,
        'video': video,
        'audio': audio,
        'description': description,
        'site_name': siteName,
      };
}
