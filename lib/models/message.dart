import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';

class Message {
  int id;
  String uuid;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Map<String, dynamic> content;
  String type;
  List<int>? attachments;
  Channel? channel;
  Sender sender;
  int? replyId;
  Message? replyTo;
  int channelId;
  int senderId;

  bool isSending = false;

  Message({
    required this.id,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.content,
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
        id: json['id'],
        uuid: json['uuid'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        content: json['content'],
        type: json['type'],
        attachments: json["attachments"] != null
            ? List<int>.from(json["attachments"])
            : null,
        channel:
            json['channel'] != null ? Channel.fromJson(json['channel']) : null,
        sender: Sender.fromJson(json['sender']),
        replyId: json['reply_id'],
        replyTo: json['reply_to'] != null
            ? Message.fromJson(json['reply_to'])
            : null,
        channelId: json['channel_id'],
        senderId: json['sender_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'content': content,
        'type': type,
        'attachments': attachments,
        'channel': channel?.toJson(),
        'sender': sender.toJson(),
        'reply_id': replyId,
        'reply_to': replyTo?.toJson(),
        'channel_id': channelId,
        'sender_id': senderId,
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
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        account: Account.fromJson(json['account']),
        channelId: json['channel_id'],
        accountId: json['account_id'],
        notify: json['notify'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'account': account.toJson(),
        'channel_id': channelId,
        'account_id': accountId,
        'notify': notify,
      };
}
