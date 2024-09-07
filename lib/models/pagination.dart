import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class PaginationResult {
  int count;
  List<dynamic>? data;

  PaginationResult({
    required this.count,
    this.data,
  });

  factory PaginationResult.fromJson(Map<String, dynamic> json) =>
      _$PaginationResultFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationResultToJson(this);
}
