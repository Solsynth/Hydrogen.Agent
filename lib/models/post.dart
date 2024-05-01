import 'package:solian/models/author.dart';

class Post {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String title;
  String description;
  String content;
  String modelType;
  int commentCount;
  int reactionCount;
  int authorId;
  int? realmId;
  Author author;
  List<Attachment>? attachments;
  Map<String, dynamic>? reactionList;

  String get dataset => '${modelType}s';

  Post({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.alias,
    required this.title,
    required this.description,
    required this.content,
    required this.modelType,
    required this.commentCount,
    required this.reactionCount,
    required this.authorId,
    this.realmId,
    required this.author,
    this.attachments,
    this.reactionList,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        alias: json['alias'],
        title: json['title'],
        description: json['description'],
        content: json['content'],
        modelType: json['model_type'],
        commentCount: json['comment_count'],
        reactionCount: json['reaction_count'],
        authorId: json['author_id'],
        realmId: json['realm_id'],
        author: Author.fromJson(json['author']),
        attachments: json['attachments'] != null
            ? List<Attachment>.from(
                json['attachments'].map((x) => Attachment.fromJson(x)))
            : List.empty(),
        reactionList: json['reaction_list'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'alias': alias,
        'title': title,
        'description': description,
        'content': content,
        'model_type': modelType,
        'comment_count': commentCount,
        'reaction_count': reactionCount,
        'author_id': authorId,
        'realm_id': realmId,
        'author': author.toJson(),
        'attachments': attachments == null
            ? List.empty()
            : List<dynamic>.from(attachments!.map((x) => x.toJson())),
        'reaction_list': reactionList,
      };
}

class Attachment {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String fileId;
  int filesize;
  String filename;
  String mimetype;
  int type;
  String externalUrl;
  Author author;
  int? articleId;
  int? momentId;
  int? commentId;
  int? authorId;

  Attachment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.fileId,
    required this.filesize,
    required this.filename,
    required this.mimetype,
    required this.type,
    required this.externalUrl,
    required this.author,
    this.articleId,
    this.momentId,
    this.commentId,
    this.authorId,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        fileId: json['file_id'],
        filesize: json['filesize'],
        filename: json['filename'],
        mimetype: json['mimetype'],
        type: json['type'],
        externalUrl: json['external_url'],
        author: Author.fromJson(json['author']),
        articleId: json['article_id'],
        momentId: json['moment_id'],
        commentId: json['comment_id'],
        authorId: json['author_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'file_id': fileId,
        'filesize': filesize,
        'filename': filename,
        'mimetype': mimetype,
        'type': type,
        'external_url': externalUrl,
        'author': author.toJson(),
        'article_id': articleId,
        'moment_id': momentId,
        'comment_id': commentId,
        'author_id': authorId,
      };
}
