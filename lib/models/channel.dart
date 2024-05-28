import 'package:solian/models/account.dart';
import 'package:solian/models/realm.dart';

class Channel {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  int type;
  List<ChannelMember>? members;
  Account account;
  int accountId;
  Realm? realm;
  int? realmId;
  bool isEncrypted;

  bool isAvailable = false;

  Channel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    required this.type,
    required this.members,
    required this.account,
    required this.accountId,
    required this.isEncrypted,
    required this.realm,
    required this.realmId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        alias: json['alias'],
        name: json['name'],
        description: json['description'],
        type: json['type'],
        members: json['members']
            ?.map((e) => ChannelMember.fromJson(e))
            .toList()
            .cast<ChannelMember>(),
        account: Account.fromJson(json['account']),
        accountId: json['account_id'],
        realm: json['realm'] != null ? Realm.fromJson(json['realm']) : null,
        realmId: json['realm_id'],
        isEncrypted: json['is_encrypted'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'alias': alias,
        'name': name,
        'description': description,
        'type': type,
        'members': members?.map((e) => e.toJson()).toList(),
        'account': account.toJson(),
        'account_id': accountId,
        'realm': realm?.toJson(),
        'realm_id': realmId,
        'is_encrypted': isEncrypted,
      };
}

class ChannelMember {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int channelId;
  int accountId;
  Account account;
  int notify;

  ChannelMember({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.channelId,
    required this.accountId,
    required this.account,
    required this.notify,
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) => ChannelMember(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        deletedAt: json['deleted_at'],
        channelId: json['channel_id'],
        accountId: json['account_id'],
        account: Account.fromJson(json['account']),
        notify: json['notify'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt,
        'channel_id': channelId,
        'account_id': accountId,
        'account': account.toJson(),
        'notify': notify,
      };
}
