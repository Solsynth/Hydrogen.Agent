import 'package:solian/models/account.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';

class Article {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String title;
  String description;
  String content;
  List<Tag>? tags;
  List<Category>? categories;
  List<int>? attachments;
  int? realmId;
  Realm? realm;
  DateTime? publishedAt;
  bool? isDraft;
  int authorId;
  Account author;
  PostMetric? metric;

  Article({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.title,
    required this.description,
    required this.content,
    required this.tags,
    required this.categories,
    required this.attachments,
    required this.realmId,
    required this.realm,
    required this.publishedAt,
    required this.isDraft,
    required this.authorId,
    required this.author,
    required this.metric,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        alias: json['alias'],
        title: json['title'],
        description: json['description'],
        content: json['content'],
        tags: json['tags']?.map((x) => Tag.fromJson(x)).toList().cast<Tag>(),
        categories: json['categories']
            ?.map((x) => Category.fromJson(x))
            .toList()
            .cast<Category>(),
        attachments: json['attachments'] != null
            ? List<int>.from(json['attachments'])
            : null,
        realmId: json['realm_id'],
        realm: json['realm'] != null ? Realm.fromJson(json['realm']) : null,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'])
            : null,
        isDraft: json['is_draft'],
        authorId: json['author_id'],
        author: Account.fromJson(json['author']),
        metric:
            json['metric'] != null ? PostMetric.fromJson(json['metric']) : null,
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
        'tags': tags,
        'categories': categories,
        'attachments': attachments,
        'realm_id': realmId,
        'realm': realm?.toJson(),
        'published_at': publishedAt?.toIso8601String(),
        'is_draft': isDraft,
        'author_id': authorId,
        'author': author.toJson(),
        'metric': metric?.toJson(),
      };
}
