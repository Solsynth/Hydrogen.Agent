import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:solian/models/account.dart';

class Channel {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String alias;
  String name;
  String description;
  int type;
  Account account;
  int accountId;
  int? realmId;
  bool isEncrypted;

  bool isAvailable = false;

  Channel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.alias,
    required this.name,
    required this.description,
    required this.type,
    required this.account,
    required this.accountId,
    required this.isEncrypted,
    this.realmId,
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
        account: Account.fromJson(json['account']),
        accountId: json['account_id'],
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
        'account': account,
        'account_id': accountId,
        'realm_id': realmId,
        'is_encrypted': isEncrypted,
      };

  IconData get icon {
    switch (type) {
      case 1:
        return FontAwesomeIcons.userGroup;
      default:
        return FontAwesomeIcons.hashtag;
    }
  }
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
