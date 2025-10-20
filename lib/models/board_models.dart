class BoardSummary {
  BoardSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String category;
  final DateTime createdAt;

  factory BoardSummary.fromJson(Map<String, dynamic> json) {
    return BoardSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ??
          json['boardCategory'] as String? ??
          'UNKNOWN',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class BoardDetail {
  BoardDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final String? imageUrl;

  factory BoardDetail.fromJson(Map<String, dynamic> json) {
    return BoardDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['boardCategory'] as String? ??
          json['category'] as String? ??
          'UNKNOWN',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class BoardInput {
  BoardInput({
    required this.title,
    required this.content,
    required this.category,
  });

  final String title;
  final String content;
  final String category;

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'category': category,
      };
}
