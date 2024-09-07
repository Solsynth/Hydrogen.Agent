// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationResult _$PaginationResultFromJson(Map<String, dynamic> json) =>
    PaginationResult(
      count: (json['count'] as num).toInt(),
      data: json['data'] as List<dynamic>?,
    );

Map<String, dynamic> _$PaginationResultToJson(PaginationResult instance) =>
    <String, dynamic>{
      'count': instance.count,
      'data': instance.data,
    };
