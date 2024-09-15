import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:solian/models/account.dart';

part 'auth.g.dart';

@JsonSerializable()
class AuthResult {
  bool isFinished;
  AuthTicket ticket;

  AuthResult({
    required this.isFinished,
    required this.ticket,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResultToJson(this);
}

@JsonSerializable()
class AuthTicket {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String location;
  String ipAddress;
  String userAgent;
  int stepRemain;
  List<String> claims;
  List<String> audiences;
  @JsonKey(defaultValue: [])
  List<int> factorTrail;
  String? grantToken;
  String? accessToken;
  String? refreshToken;
  DateTime? expiredAt;
  DateTime? availableAt;
  DateTime? lastGrantAt;
  String? nonce;
  int? clientId;
  Account account;
  int accountId;

  AuthTicket({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.location,
    required this.ipAddress,
    required this.userAgent,
    required this.stepRemain,
    required this.claims,
    required this.audiences,
    required this.factorTrail,
    required this.grantToken,
    required this.accessToken,
    required this.refreshToken,
    required this.expiredAt,
    required this.availableAt,
    required this.lastGrantAt,
    required this.nonce,
    required this.clientId,
    required this.account,
    required this.accountId,
  });

  factory AuthTicket.fromJson(Map<String, dynamic> json) =>
      _$AuthTicketFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTicketToJson(this);
}

@JsonSerializable()
class AuthFactor {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  int type;
  Map<String, dynamic>? config;
  Account account;
  int accountId;

  AuthFactor({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.type,
    required this.config,
    required this.account,
    required this.accountId,
  });

  factory AuthFactor.fromJson(Map<String, dynamic> json) =>
      _$AuthFactorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthFactorToJson(this);
}
