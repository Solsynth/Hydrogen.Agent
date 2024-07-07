import 'package:solian/models/account.dart';
import 'package:solian/models/feed.dart';
import 'package:solian/models/realm.dart';

class Post {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String content;
  List<Tag>? tags;
  List<Category>? categories;
  List<Post>? replies;
  List<int>? attachments;
  int? replyId;
  int? repostId;
  int? realmId;
  Post? replyTo;
  Post? repostTo;
  Realm? realm;
  DateTime? publishedAt;
  int authorId;
  Account author;
  int replyCount;
  int reactionCount;
  Map<String, int> reactionList;

  Post({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.content,
    required this.tags,
    required this.categories,
    required this.replies,
    required this.attachments,
    required this.replyId,
    required this.repostId,
    required this.realmId,
    required this.replyTo,
    required this.repostTo,
    required this.realm,
    required this.publishedAt,
    required this.authorId,
    required this.author,
    required this.replyCount,
    required this.reactionCount,
    required this.reactionList,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        alias: json['alias'],
        content: json['content'],
        tags: json['tags']?.map((x) => Tag.fromJson(x)).toList().cast<Tag>(),
        categories: json['categories']
            ?.map((x) => Category.fromJson(x))
            .toList()
            .cast<Category>(),
        replies: json['replies'],
        attachments: json['attachments'] != null
            ? List<int>.from(json['attachments'])
            : null,
        replyId: json['reply_id'],
        repostId: json['repost_id'],
        realmId: json['realm_id'],
        replyTo:
            json['reply_to'] != null ? Post.fromJson(json['reply_to']) : null,
        repostTo:
            json['repost_to'] != null ? Post.fromJson(json['repost_to']) : null,
        realm: json['realm'] != null ? Realm.fromJson(json['realm']) : null,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'])
            : null,
        authorId: json['author_id'],
        author: Account.fromJson(json['author']),
        replyCount: json['reply_count'],
        reactionCount: json['reaction_count'],
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
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'alias': alias,
        'content': content,
        'tags': tags,
        'categories': categories,
        'replies': replies,
        'attachments': attachments,
        'reply_id': replyId,
        'repost_id': repostId,
        'realm_id': realmId,
        'reply_to': replyTo?.toJson(),
        'repost_to': repostTo?.toJson(),
        'realm': realm?.toJson(),
        'published_at': publishedAt?.toIso8601String(),
        'author_id': authorId,
        'author': author.toJson(),
        'reply_count': replyCount,
        'reaction_count': reactionCount,
        'reaction_list': reactionList,
      };
}
