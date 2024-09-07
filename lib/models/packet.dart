import 'package:freezed_annotation/freezed_annotation.dart';

part 'packet.g.dart';

@JsonSerializable()
class NetworkPackage {
  @JsonKey(name: 'w')
  String method;
  @JsonKey(name: 'e')
  String? endpoint;
  @JsonKey(name: 'm')
  String? message;
  @JsonKey(name: 'p')
  Map<String, dynamic>? payload;

  NetworkPackage({
    required this.method,
    this.endpoint,
    this.message,
    this.payload,
  });

  factory NetworkPackage.fromJson(Map<String, dynamic> json) =>
      _$NetworkPackageFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkPackageToJson(this);
}
