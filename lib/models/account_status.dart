class AccountStatus {
  bool isDisturbable;
  bool isOnline;
  DateTime? lastSeenAt;
  dynamic status;

  AccountStatus({
    required this.isDisturbable,
    required this.isOnline,
    required this.lastSeenAt,
    required this.status,
  });

  factory AccountStatus.fromJson(Map<String, dynamic> json) => AccountStatus(
    isDisturbable: json['is_disturbable'],
    isOnline: json['is_online'],
    lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at']) : null,
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'is_disturbable': isDisturbable,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'status': status,
  };
}
