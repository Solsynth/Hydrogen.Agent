import 'package:solian/models/account.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/realm.dart';

class Post {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? editedAt;
  DateTime? deletedAt;
  String? alias;
  String? areaAlias;
  dynamic body;
  List<Tag>? tags;
  List<Category>? categories;
  List<Post>? replies;
  String type;
  int? replyId;
  int? repostId;
  int? realmId;
  Post? replyTo;
  Post? repostTo;
  Realm? realm;
  DateTime? publishedAt;
  DateTime? publishedUntil;
  DateTime? pinnedAt;
  bool? isDraft;
  int authorId;
  Account author;
  PostMetric? metric;

  Post({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.editedAt,
    required this.deletedAt,
    required this.alias,
    required this.areaAlias,
    required this.type,
    required this.body,
    required this.tags,
    required this.categories,
    required this.replies,
    required this.replyId,
    required this.repostId,
    required this.realmId,
    required this.replyTo,
    required this.repostTo,
    required this.realm,
    required this.publishedAt,
    required this.publishedUntil,
    required this.pinnedAt,
    required this.isDraft,
    required this.authorId,
    required this.author,
    required this.metric,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        alias: json['alias'],
        areaAlias: json['area_alias'],
        type: json['type'],
        body: json['body'],
        tags: json['tags']?.map((x) => Tag.fromJson(x)).toList().cast<Tag>(),
        categories: json['categories']
            ?.map((x) => Category.fromJson(x))
            .toList()
            .cast<Category>(),
        replies: json['replies'],
        replyId: json['reply_id'],
        repostId: json['repost_id'],
        realmId: json['realm_id'],
        replyTo:
            json['reply_to'] != null ? Post.fromJson(json['reply_to']) : null,
        repostTo:
            json['repost_to'] != null ? Post.fromJson(json['repost_to']) : null,
        realm: json['realm'] != null ? Realm.fromJson(json['realm']) : null,
        editedAt: json['edited_at'] != null
            ? DateTime.parse(json['edited_at'])
            : null,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'])
            : null,
        publishedUntil: json['published_until'] != null
            ? DateTime.parse(json['published_until'])
            : null,
        pinnedAt: json['pinned_at'] != null
            ? DateTime.parse(json['pinned_at'])
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
        'edited_at': editedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'alias': alias,
        'area_alias': areaAlias,
        'type': type,
        'body': body,
        'tags': tags,
        'categories': categories,
        'replies': replies,
        'reply_id': replyId,
        'repost_id': repostId,
        'realm_id': realmId,
        'reply_to': replyTo?.toJson(),
        'repost_to': repostTo?.toJson(),
        'realm': realm?.toJson(),
        'published_at': publishedAt?.toIso8601String(),
        'published_until': publishedUntil?.toIso8601String(),
        'pinned_at': pinnedAt?.toIso8601String(),
        'is_draft': isDraft,
        'author_id': authorId,
        'author': author.toJson(),
        'metric': metric?.toJson(),
      };
}

class PostMetric {
  int reactionCount;
  Map<String, int> reactionList;
  int replyCount;

  PostMetric({
    required this.reactionCount,
    required this.reactionList,
    required this.replyCount,
  });

  factory PostMetric.fromJson(Map<String, dynamic> json) => PostMetric(
        reactionCount: json['reaction_count'],
        replyCount: json['reply_count'],
        reactionList: json['reaction_list'] != null
            ? json['reaction_list']
                .map((key, value) => MapEntry(
                    key,
                    int.tryParse(value.toString()) ??
                        (value is double ? value.toInt() : null)))
                .cast<String, int>()
            : {},
      );

  Map<String, dynamic> toJson() => {
        'reaction_count': reactionCount,
        'reply_count': replyCount,
        'reaction_list': reactionList,
      };
}
