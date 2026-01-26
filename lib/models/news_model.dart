class News {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  final String? updatedAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      content: json['content'] ?? 'No Content',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }
}

class NewsResponse {
  final List<News> data;
  final NewsLinks? links;
  final NewsMeta? meta;

  NewsResponse({required this.data, this.links, this.meta});

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List?;
    List<News> news = dataList != null
        ? dataList.map((i) => News.fromJson(i)).toList()
        : [];

    return NewsResponse(
      data: news,
      links: json['links'] != null ? NewsLinks.fromJson(json['links']) : null,
      meta: json['meta'] != null ? NewsMeta.fromJson(json['meta']) : null,
    );
  }
}

class NewsLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  NewsLinks({this.first, this.last, this.prev, this.next});

  factory NewsLinks.fromJson(Map<String, dynamic> json) {
    return NewsLinks(
      first: json['first'],
      last: json['last'],
      prev: json['prev'],
      next: json['next'],
    );
  }
}

class NewsMeta {
  final int? currentPage;
  final int? from;
  final int? lastPage;
  final int? total;

  NewsMeta({this.currentPage, this.from, this.lastPage, this.total});

  factory NewsMeta.fromJson(Map<String, dynamic> json) {
    return NewsMeta(
      currentPage: json['current_page'],
      from: json['from'],
      lastPage: json['last_page'],
      total: json['total'],
    );
  }
}
