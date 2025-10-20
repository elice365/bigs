typedef FromJson<T> = T Function(Map<String, dynamic> json);

class PagedResult<T> {
  PagedResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });

  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    FromJson<T> converter,
  ) {
    final content = json['content'] as List<dynamic>? ?? const [];
    final items = content
        .whereType<Map<String, dynamic>>()
        .map(converter)
        .toList(growable: false);

    return PagedResult(
      items: items,
      pageNumber: json['number'] as int? ?? 0,
      pageSize: json['size'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? items.length,
      isLast: json['last'] as bool? ?? true,
    );
  }
}
