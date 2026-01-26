import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  static const String _baseUrl = 'https://akum-connect.mamat.com.ng/api';

  // Simple in-memory cache
  final List<News> _cachedList = [];
  final Map<int, News> _cachedDetails = {};

  // Use to check if we have fetched list at least once to avoid aggressive refetching if needed (optional)
  // For now, pull-to-refresh will force update, otherwise we return cached if available?
  // User req: "Implement simple in-memory caching to avoid refetching details unnecessarily"

  Future<List<News>> getNews({int page = 1, bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedList.isNotEmpty && page == 1) {
      return _cachedList;
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/news?page=$page'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonBody);

        if (page == 1) {
          _cachedList.clear();
          _cachedList.addAll(newsResponse.data);
          // Also cache details for individual items found in list
          for (var item in newsResponse.data) {
            _cachedDetails[item.id] = item;
          }
        } else {
          // For pagination, we might want to append, but current UI req is just list.
          // If we support load more, we would append.
          // For now assume page 1 main list.
        }

        return newsResponse.data;
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      rethrow;
    }
  }

  Future<News> getNewsDetail(int id) async {
    if (_cachedDetails.containsKey(id)) {
      // Check if the cached version has content (in case list version is summary only,
      // but API text says list has content too. Let's assume list might be truncated or full.
      // API docs show list has "content" and detail has "content".
      // Often list content is truncated. If the cached object from list is sufficient, return it.
      // However, usually detail endpoint might have more fields.
      // Let's assume we want to fetch fresh detail if we only have list item, OR
      // just trust the cache if we want to save bandwidth.
      // User says: "Implement simple in-memory caching to avoid refetching details unnecessarily"
      // So if we have it, return it. We can rely on the user pulling to refresh the list to update "summary" content,
      // but if detail provides MORE info, we might want to fetch.
      // The prompt says "All News Response" and "Single News Response" have same structure for data item.
      // So likely we can stick to cache. But let's verify if content is truncated in list?
      // Prompt says "Short preview of content (first 2–3 lines)" for list UI, but data might be full string.
      // I'll optimistically use cache. If not in cache, fetch.
      return _cachedDetails[id]!;
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/news/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        final newsItem = News.fromJson(jsonBody['data']);
        _cachedDetails[id] = newsItem;
        return newsItem;
      } else {
        throw Exception('Failed to load news detail');
      }
    } catch (e) {
      debugPrint('Error fetching news detail: $e');
      rethrow;
    }
  }
}
