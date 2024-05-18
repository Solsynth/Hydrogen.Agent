class NetworkPackage {
  String method;
  String? message;
  Map<String, dynamic>? payload;

  NetworkPackage({
    required this.method,
    this.message,
    this.payload,
  });

  factory NetworkPackage.fromJson(Map<String, dynamic> json) => NetworkPackage(
        method: json['w'],
        message: json['m'],
        payload: json['p'],
      );

  Map<String, dynamic> toJson() => {
        'w': method,
        'm': message,
        'p': payload,
      };
}
