class PagedResponse<T> {
  const PagedResponse({
    required this.data,
    required this.total,
    required this.page,
  });

  final List<T> data;
  final int total;
  final int page;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final raw = json['data'] as List<dynamic>? ?? [];
    return PagedResponse(
      data:  raw.map((e) => fromMap(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? raw.length,
      page:  json['page']  as int? ?? 1,
    );
  }
}
