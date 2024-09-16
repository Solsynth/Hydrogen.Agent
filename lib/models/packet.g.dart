// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkPackage _$NetworkPackageFromJson(Map<String, dynamic> json) =>
    NetworkPackage(
      method: json['w'] as String? ?? 'unknown',
      endpoint: json['e'] as String?,
      message: json['m'] as String?,
      payload: json['p'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NetworkPackageToJson(NetworkPackage instance) =>
    <String, dynamic>{
      'w': instance.method,
      'e': instance.endpoint,
      'm': instance.message,
      'p': instance.payload,
    };
