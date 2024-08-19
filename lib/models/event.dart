import 'package:solian/models/account.dart';
import 'package:solian/models/channel.dart';

class Event {
  int id;
  String uuid;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  Map<String, dynamic> body;
  String type;
  Channel? channel;
  Sender sender;
  int channelId;
  int senderId;

  bool isPending = false;

  Event({
    required this.id,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.body,
    required this.type,
    this.channel,
    required this.sender,
    required this.channelId,
    required this.senderId,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'],
        uuid: json['uuid'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        body: json['body'],
        type: json['type'],
        channel:
            json['channel'] != null ? Channel.fromJson(json['channel']) : null,
        sender: Sender.fromJson(json['sender']),
        channelId: json['channel_id'],
        senderId: json['sender_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'body': body,
        'type': type,
        'channel': channel?.toJson(),
        'sender': sender.toJson(),
        'channel_id': channelId,
        'sender_id': senderId,
      };
}

class EventMessageBody {
  String text;
  String algorithm;
  List<String>? attachments;
  int? quoteEvent;
  int? relatedEvent;
  List<int>? relatedUsers;

  EventMessageBody({
    required this.text,
    required this.algorithm,
    required this.attachments,
    required this.quoteEvent,
    required this.relatedEvent,
    required this.relatedUsers,
  });

  factory EventMessageBody.fromJson(Map<String, dynamic> json) =>
      EventMessageBody(
        text: json['text'] ?? '',
        algorithm: json['algorithm'] ?? 'plain',
        attachments: json['attachments'] != null
            ? List<String>.from(json['attachments']?.whereType<String>())
            : null,
        quoteEvent: json['quote_event'],
        relatedEvent: json['related_event'],
        relatedUsers: json['related_users'] != null
            ? List<int>.from(json['related_users'].map((x) => x))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'algorithm': algorithm,
        'attachments': attachments?.cast<dynamic>(),
        'quote_event': quoteEvent,
        'related_event': relatedEvent,
        'related_users': relatedUsers?.cast<dynamic>(),
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
