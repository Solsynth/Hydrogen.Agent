class AccountStatus {
  bool isDisturbable;
  bool isOnline;
  DateTime? lastSeenAt;
  Status? status;

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
    status: json['status'] != null ? Status.fromJson(json['status']) : null,
  );

  Map<String, dynamic> toJson() => {
    'is_disturbable': isDisturbable,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'status': status?.toJson(),
  };
}

class Status {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String type;
  String label;
  int attitude;
  bool isNoDisturb;
  bool isInvisible;
  DateTime? clearAt;
  int accountId;

  Status({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.type,
    required this.label,
    required this.attitude,
    required this.isNoDisturb,
    required this.isInvisible,
    required this.clearAt,
    required this.accountId,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    id: json['id'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    type: json['type'],
    label: json['label'],
    attitude: json['attitude'],
    isNoDisturb: json['is_no_disturb'],
    isInvisible: json['is_invisible'],
    clearAt: json['clear_at'] != null ? DateTime.parse(json['clear_at']) : null,
    accountId: json['account_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'type': type,
    'label': label,
    'attitude': attitude,
    'is_no_disturb': isNoDisturb,
    'is_invisible': isInvisible,
    'clear_at': clearAt?.toIso8601String(),
    'account_id': accountId,
  };
}
