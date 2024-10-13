import 'package:json_annotation/json_annotation.dart';
import 'package:solian/models/account.dart';

part 'audit_log.g.dart';

@JsonSerializable()
class AuditEvent {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String type;
  String target;
  String location;
  String ipAddress;
  String userAgent;
  Account account;
  int accountId;

  AuditEvent({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.type,
    required this.target,
    required this.location,
    required this.ipAddress,
    required this.userAgent,
    required this.account,
    required this.accountId,
  });

  static AuditEvent fromJson(Map<String, dynamic> json) =>
      _$AuditEventFromJson(json);

  Map<String, dynamic> toJson() => _$AuditEventToJson(this);
}
