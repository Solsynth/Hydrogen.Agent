import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/models/post_categories.dart';
import 'package:solian/models/realm.dart';

part 'post.g.dart';

class PostPreload {
  List<Attachment> attachments;

  PostPreload({
    required this.attachments,
  });
}

@JsonSerializable()
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  PostPreload? preload;

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

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@JsonSerializable()
class PostMetric {
  int reactionCount;
  @JsonKey(defaultValue: {})
  Map<String, int> reactionList;
  int replyCount;

  PostMetric({
    required this.reactionCount,
    required this.reactionList,
    required this.replyCount,
  });

  factory PostMetric.fromJson(Map<String, dynamic> json) =>
      _$PostMetricFromJson(json);

  Map<String, dynamic> toJson() => _$PostMetricToJson(this);
}
