import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class GroqAiProvider implements AiProvider {
  @override
  String get id => 'groq';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  final List<Map<String, String>> _history = [];
  String? _systemPrompt;

  GroqAiProvider() {
    _resetHistory();
  }

  @override
  void init(String systemPrompt) {
    _systemPrompt = systemPrompt;
    _resetHistory();
  }

  void _resetHistory() {
    _history.clear();
    _history.add({
      "role": "system",
      "content":
          _systemPrompt ??
          "You are an educational AI assistant for Abdulkadir Kure University.",
    });
  }

  @override
  Future<String> sendMessage(String message) async {
    if (!dotenv.isInitialized) {
      throw Exception('Environment not loaded');
    }

    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API Key missing');
    }

    _history.add({"role": "user", "content": message});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': _history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].toString();
        _history.add({"role": "assistant", "content": content});
        return content;
      } else {
        final body = response.body.toLowerCase();
        if (response.statusCode == 429 || body.contains('rate limit')) {
          throw Exception('QuotaExceeded');
        }
        if (response.statusCode == 401) {
          throw Exception('AuthError');
        }
        throw Exception('Groq Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq Request Failed: $e');
      rethrow;
    }
  }
}
