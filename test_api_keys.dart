import "package:flutter/foundation.dart";
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  debugPrint("🔍 Loading .env file...");
  final env = await _loadEnv();

  if (env.isEmpty) {
    debugPrint("❌ No .env file found or empty.");
    return;
  }

  final geminiKey = env['GEMINI_API_KEY'];
  final groqKey = env['GROQ_API_KEY'];
  final sambanovaKey = env['SAMBANOVA_API_KEY'];

  debugPrint("\n-------------------------------------------");
  await _testGemini(geminiKey);
  debugPrint("-------------------------------------------");
  await _testGroq(groqKey);
  debugPrint("-------------------------------------------");
  await _testSambanova(sambanovaKey);
  debugPrint("-------------------------------------------");
}

Future<Map<String, String>> _loadEnv() async {
  final file = File('.env');
  if (!await file.exists()) return {};

  final lines = await file.readAsLines();
  final Map<String, String> env = {};

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }
  return env;
}

Future<void> _testGemini(String? key) async {
  if (key == null || key.isEmpty) {
    debugPrint("⚠️ Gemini: Skipped (Key missing)");
    return;
  }
  debugPrint("⏳ Testing Gemini models (via google_generative_ai)...");

  // 1. List valid models for this key
  debugPrint("🔍 Listing available models for this key...");
  try {
    final listUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
    );
    final listResponse = await http.get(listUrl);
    if (listResponse.statusCode == 200) {
      final data = jsonDecode(listResponse.body);
      final models = (data['models'] as List)
          .map((m) => m['name'].toString().replaceFirst('models/', ''))
          .toList();
      debugPrint("📋 Available Models: $models");

      if (models.contains('gemini-2.5-flash')) {
        debugPrint("✅ gemini-2.5-flash IS available!");
      } else {
        debugPrint(
          "⚠️ gemini-2.5-flash is NOT in the list of available models.",
        );
      }
    } else {
      debugPrint("❌ Failed to list models. Status: ${listResponse.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Error listing models: $e");
  }

  // 2. Try gemini-2.5-flash
  try {
    debugPrint("Trying gemini-2.5-flash...");
    var model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: key);
    var response = await model.generateContent([Content.text('Hello')]);
    debugPrint(
      "✅ Gemini: Success (2.5 Flash)! Response: ${response.text?.substring(0, 20)}...",
    );
    return;
  } catch (e) {
    debugPrint("⚠️ gemini-2.5-flash failed: $e");
  }

  try {
    debugPrint("Trying gemini-1.5-flash...");
    var model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
    var response = await model.generateContent([Content.text('Hello')]);
    debugPrint(
      "✅ Gemini: Success (1.5 Flash)! Response: ${response.text?.substring(0, 20)}...",
    );
    return;
  } catch (e) {
    debugPrint("⚠️ gemini-1.5-flash failed: $e");
  }

  try {
    debugPrint("Trying gemini-1.5-flash-latest...");
    var model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: key);
    var response = await model.generateContent([Content.text('Hello')]);
    debugPrint(
      "✅ Gemini: Success (1.5 Flash Latest)! Response: ${response.text?.substring(0, 20)}...",
    );
    return;
  } catch (e) {
    debugPrint("⚠️ gemini-1.5-flash-latest failed: $e");
  }

  try {
    debugPrint("Trying gemini-pro...");
    var model = GenerativeModel(model: 'gemini-pro', apiKey: key);
    var response = await model.generateContent([Content.text('Hello')]);
    debugPrint(
      "✅ Gemini: Success (gemini-pro)! Response: ${response.text?.substring(0, 20)}...",
    );
    return;
  } catch (e) {
    debugPrint("⚠️ gemini-pro failed: $e");
  }

  debugPrint("❌ All Gemini models failed.");
}

Future<void> _testGroq(String? key) async {
  if (key == null || key.isEmpty) {
    debugPrint("⚠️ Groq: Skipped (Key missing)");
    return;
  }
  debugPrint("⏳ Testing Groq...");

  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        "model": "llama-3.1-8b-instant", // Updated model
        "messages": [
          {"role": "user", "content": "Hello"},
        ],
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Groq: Success! Response received.");
    } else {
      debugPrint("❌ Groq: Failed. Status: ${response.statusCode}");
      debugPrint("Content: ${response.body}");
    }
  } catch (e) {
    debugPrint("❌ Groq: Error - $e");
  }
}

Future<void> _testSambanova(String? key) async {
  if (key == null || key.isEmpty) {
    debugPrint("⚠️ SambaNova: Skipped (Key missing)");
    return;
  }
  debugPrint("⏳ Testing SambaNova (8B Model)...");

  final url = Uri.parse('https://api.sambanova.ai/v1/chat/completions');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        "model": "Meta-Llama-3.1-8B-Instruct", // Downgraded to 8B
        "messages": [
          {"role": "user", "content": "Hello"},
        ],
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ SambaNova: Success! Response received.");
    } else {
      debugPrint("❌ SambaNova: Failed. Status: ${response.statusCode}");
      debugPrint("Content: ${response.body}");
    }
  } catch (e) {
    debugPrint("❌ SambaNova: Error - $e");
  }
}
