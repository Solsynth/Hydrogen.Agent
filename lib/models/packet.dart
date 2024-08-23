class NetworkPackage {
  String method;
  String? endpoint;
  String? message;
  Map<String, dynamic>? payload;

  NetworkPackage({
    required this.method,
    this.endpoint,
    this.message,
    this.payload,
  });

  factory NetworkPackage.fromJson(Map<String, dynamic> json) => NetworkPackage(
        method: json['w'],
        endpoint: json['e'],
        message: json['m'],
        payload: json['p'],
      );

  Map<String, dynamic> toJson() => {
        'w': method,
        'e': endpoint,
        'm': message,
        'p': payload,
      };
}
