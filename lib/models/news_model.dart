class News {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  final String? updatedAt;
  final String imageUrl;
  final String category;
  final String author;
  final int readTimeMinutes;
  final bool isFeatured;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl = 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800&q=80',
    this.category = 'Campus News',
    this.author = 'University Editorial Board',
    this.readTimeMinutes = 3,
    this.isFeatured = false,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'No Title',
      content: json['content'] ?? 'No Content',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      imageUrl: json['image_url'] ??
          json['image'] ??
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800&q=80',
      category: json['category'] ?? 'Campus News',
      author: json['author'] ?? 'University Editorial Board',
      readTimeMinutes: json['read_time_minutes'] ?? 3,
      isFeatured: json['is_featured'] ?? false,
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
