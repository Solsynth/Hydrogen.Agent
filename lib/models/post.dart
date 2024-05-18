import 'package:solian/models/account.dart';
import 'package:solian/models/realm.dart';

class Post {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String content;
  dynamic tags;
  dynamic categories;
  dynamic reactions;
  List<Post>? replies;
  List<String>? attachments;
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
  dynamic reactionList;

  Post({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.content,
    required this.tags,
    required this.categories,
    required this.reactions,
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
    id: json["id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"] != null ? DateTime.parse(json['deleted_at']) : null,
    alias: json["alias"],
    content: json["content"],
    tags: json["tags"],
    categories: json["categories"],
    reactions: json["reactions"],
    replies: json["replies"],
    attachments: json["attachments"],
    replyId: json["reply_id"],
    repostId: json["repost_id"],
    realmId: json["realm_id"],
    replyTo: json["reply_to"] == null ? null : Post.fromJson(json["reply_to"]),
    repostTo: json["repost_to"],
    realm: json["realm"],
    publishedAt: json["published_at"],
    authorId: json["author_id"],
    author: Account.fromJson(json["author"]),
    replyCount: json["reply_count"],
    reactionCount: json["reaction_count"],
    reactionList: json["reaction_list"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "deleted_at": deletedAt,
    "alias": alias,
    "content": content,
    "tags": tags,
    "categories": categories,
    "reactions": reactions,
    "replies": replies,
    "attachments": attachments,
    "reply_id": replyId,
    "repost_id": repostId,
    "realm_id": realmId,
    "reply_to": replyTo?.toJson(),
    "repost_to": repostTo,
    "realm": realm,
    "published_at": publishedAt,
    "author_id": authorId,
    "author": author.toJson(),
    "reply_count": replyCount,
    "reaction_count": reactionCount,
    "reaction_list": reactionList,
  };
}