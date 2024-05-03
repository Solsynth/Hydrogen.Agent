class PersonalPage {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String content;
  String script;
  String style;
  Map<String, String>? links;
  int accountId;

  PersonalPage({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.content,
    required this.script,
    required this.style,
    this.links,
    required this.accountId,
  });

  factory PersonalPage.fromJson(Map<String, dynamic> json) => PersonalPage(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
        content: json['content'],
        script: json['script'],
        style: json['style'],
        links: json['links'],
        accountId: json['account_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'content': content,
        'script': script,
        'style': style,
        'links': links,
        'account_id': accountId,
      };
}
