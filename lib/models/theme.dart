import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

@JsonSerializable(converters: [ColorConverter()])
class SolianThemeData {
  String id;
  Color seedColor;
  String? fontFamily;
  List<String>? fontFamilyFallback;

  SolianThemeData({
    required this.id,
    required this.seedColor,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  factory SolianThemeData.fromJson(Map<String, dynamic> json) =>
      _$SolianThemeDataFromJson(json);

  Map<String, dynamic> toJson() => _$SolianThemeDataToJson(this);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is SolianThemeData) {
      return id == other.id;
    }
    return false;
  }
}

class ColorConverter extends JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) {
    return Color(json);
  }

  @override
  int toJson(Color object) {
    return object.value;
  }
}
