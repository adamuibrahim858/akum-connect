import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_provider.dart';

class GeminiAiProvider implements AiProvider {
  @override
  String get id => 'gemini';

  static const String _modelName = 'gemini-2.5-flash';

  GenerativeModel? _model;
  ChatSession? _chat;
  String? _systemPrompt;

  GeminiAiProvider() {
    _init();
  }

  @override
  void init(String systemPrompt) {
    _systemPrompt = systemPrompt;
    _startChat();
  }

  void _init() {
    if (!dotenv.isInitialized) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    _model = GenerativeModel(model: _modelName, apiKey: apiKey);
    _startChat();
  }

  void _startChat() {
    if (_model == null) return;
    final prompt = _systemPrompt ?? "You are an educational AI assistant.";
    _chat = _model!.startChat(history: [Content.text(prompt)]);
  }

  @override
  Future<String> sendMessage(String message) async {
    if (_model == null) {
      _init();
      if (_model == null) throw Exception('Gemini API Key missing');
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      if (response.text == null) throw Exception('Empty response');
      return response.text!;
    } catch (e) {
      debugPrint("❌ Gemini Failed: $e");
      rethrow; // Let Orchestrator handle fallback
    }
  }

  /// Direct generation support for educational tasks with optional multimodal PDF bytes
  Future<String> generatePrompt({
    required String prompt,
    Uint8List? pdfBytes,
  }) async {
    if (_model == null) {
      _init();
      if (_model == null) throw Exception('Gemini API Key missing');
    }

    try {
      final List<Part> parts = [];
      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        parts.add(DataPart('application/pdf', pdfBytes));
      }
      parts.add(TextPart(prompt));

      final response = await _model!.generateContent([Content.multi(parts)]);
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return response.text!;
    } catch (e) {
      debugPrint("❌ Gemini generatePrompt Failed: $e");
      rethrow;
    }
  }
}
