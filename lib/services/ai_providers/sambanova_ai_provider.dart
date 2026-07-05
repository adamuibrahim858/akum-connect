import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class SambanovaAiProvider implements AiProvider {
  @override
  String get id => 'sambanova';

  static const String _baseUrl = 'https://api.sambanova.ai/v1/chat/completions';

  // Updating to 8B which is usually available
  static const String _model =
      'Meta-Llama-3.1-8B-Instruct'; // Reverted to try smart model again, user to downgrade if needed

  final List<Map<String, String>> _history = [];
  String? _systemPrompt;

  SambanovaAiProvider() {
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

    final apiKey = dotenv.env['SAMBANOVA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('SambaNova API Key missing');
    }

    _history.add({"role": "user", "content": message});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'model': _model, 'messages': _history}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].toString();
        _history.add({"role": "assistant", "content": content});
        return content;
      } else {
        if (response.statusCode == 429) {
          throw Exception('QuotaExceeded');
        }
        if (response.statusCode == 401) {
          throw Exception('AuthError');
        }
        throw Exception(
          'SambaNova Error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('SambaNova Request Failed: $e');
      rethrow;
    }
  }
}
