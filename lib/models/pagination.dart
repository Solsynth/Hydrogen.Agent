class PaginationResult {
  int count;
  List<dynamic>? data;

  PaginationResult({
    required this.count,
    this.data,
  });

  factory PaginationResult.fromJson(Map<String, dynamic> json) =>
      PaginationResult(count: json["count"], data: json["data"]);

  Map<String, dynamic> toJson() => {
        "count": count,
        "data": data,
      };
}
