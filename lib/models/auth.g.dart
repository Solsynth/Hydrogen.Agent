// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResult _$AuthResultFromJson(Map<String, dynamic> json) => AuthResult(
      isFinished: json['is_finished'] as bool,
      ticket: AuthTicket.fromJson(json['ticket'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResultToJson(AuthResult instance) =>
    <String, dynamic>{
      'is_finished': instance.isFinished,
      'ticket': instance.ticket.toJson(),
    };

AuthTicket _$AuthTicketFromJson(Map<String, dynamic> json) => AuthTicket(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      location: json['location'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      stepRemain: (json['step_remain'] as num).toInt(),
      claims:
          (json['claims'] as List<dynamic>).map((e) => e as String).toList(),
      audiences:
          (json['audiences'] as List<dynamic>).map((e) => e as String).toList(),
      factorTrail: (json['factor_trail'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      grantToken: json['grant_token'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiredAt: json['expired_at'] == null
          ? null
          : DateTime.parse(json['expired_at'] as String),
      availableAt: json['available_at'] == null
          ? null
          : DateTime.parse(json['available_at'] as String),
      lastGrantAt: json['last_grant_at'] == null
          ? null
          : DateTime.parse(json['last_grant_at'] as String),
      nonce: json['nonce'] as String?,
      clientId: (json['client_id'] as num?)?.toInt(),
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$AuthTicketToJson(AuthTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'location': instance.location,
      'ip_address': instance.ipAddress,
      'user_agent': instance.userAgent,
      'step_remain': instance.stepRemain,
      'claims': instance.claims,
      'audiences': instance.audiences,
      'factor_trail': instance.factorTrail,
      'grant_token': instance.grantToken,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expired_at': instance.expiredAt?.toIso8601String(),
      'available_at': instance.availableAt?.toIso8601String(),
      'last_grant_at': instance.lastGrantAt?.toIso8601String(),
      'nonce': instance.nonce,
      'client_id': instance.clientId,
      'account': instance.account.toJson(),
      'account_id': instance.accountId,
    };

AuthFactor _$AuthFactorFromJson(Map<String, dynamic> json) => AuthFactor(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      type: (json['type'] as num).toInt(),
      config: json['config'] as Map<String, dynamic>?,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      accountId: (json['account_id'] as num).toInt(),
    );

Map<String, dynamic> _$AuthFactorToJson(AuthFactor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'type': instance.type,
      'config': instance.config,
      'account': instance.account.toJson(),
      'account_id': instance.accountId,
    };
