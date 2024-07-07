class FeedRecord {
  String type;
  Map<String, dynamic> data;
  DateTime createdAt;

  FeedRecord({
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory FeedRecord.fromJson(Map<String, dynamic> json) => FeedRecord(
        type: json['type'],
        data: json['data'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'created_at': createdAt.toIso8601String(),
      };
}
