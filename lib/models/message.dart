import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/post.dart';

class Message {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String content;
  dynamic metadata;
  int type;
  List<Attachment>? attachments;
  Channel? channel;
  Sender sender;
  int? replyId;
  Message? replyTo;
  int channelId;
  int senderId;

  Message({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.content,
    required this.metadata,
    required this.type,
    this.attachments,
    this.channel,
    required this.sender,
    required this.replyId,
    required this.replyTo,
    required this.channelId,
    required this.senderId,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        content: json["content"],
        metadata: json["metadata"],
        type: json["type"],
        attachments: List<Attachment>.from(json["attachments"]?.map((x) => Attachment.fromJson(x)) ?? List.empty()),
        channel: Channel.fromJson(json["channel"]),
        sender: Sender.fromJson(json["sender"]),
        replyId: json["reply_id"],
        replyTo: json["reply_to"] != null ? Message.fromJson(json["reply_to"]) : null,
        channelId: json["channel_id"],
        senderId: json["sender_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "content": content,
        "metadata": metadata,
        "type": type,
        "attachments": List<dynamic>.from(attachments?.map((x) => x.toJson()) ?? List.empty()),
        "channel": channel?.toJson(),
        "sender": sender.toJson(),
        "reply_id": replyId,
        "reply_to": replyTo?.toJson(),
        "channel_id": channelId,
        "sender_id": senderId,
      };
}

class Sender {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Account account;
  int channelId;
  int accountId;
  int notify;

  Sender({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.account,
    required this.channelId,
    required this.accountId,
    required this.notify,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        account: Account.fromJson(json["account"]),
        channelId: json["channel_id"],
        accountId: json["account_id"],
        notify: json["notify"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "account": account.toJson(),
        "channel_id": channelId,
        "account_id": accountId,
        "notify": notify,
      };
}