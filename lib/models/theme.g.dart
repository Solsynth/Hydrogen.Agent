// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SolianThemeData _$SolianThemeDataFromJson(Map<String, dynamic> json) =>
    SolianThemeData(
      id: json['id'] as String,
      seedColor:
          const ColorConverter().fromJson((json['seed_color'] as num).toInt()),
      fontFamily: json['font_family'] as String?,
      fontFamilyFallback: (json['font_family_fallback'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SolianThemeDataToJson(SolianThemeData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seed_color': const ColorConverter().toJson(instance.seedColor),
      'font_family': instance.fontFamily,
      'font_family_fallback': instance.fontFamilyFallback,
    };
