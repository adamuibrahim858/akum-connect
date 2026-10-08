import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'dart:io';

void main() async {
  String? envKey;
  final envFile = File('.env');
  if (await envFile.exists()) {
    final lines = await envFile.readAsLines();
    for (var line in lines) {
      if (line.startsWith('GEMINI_API_KEY=')) {
        envKey = line.substring('GEMINI_API_KEY='.length).trim();
      }
    }
  }

  final keys = [
    if (envKey != null && envKey.isNotEmpty) envKey else "YOUR_GEMINI_API_KEY",
  ];

  final models = [
    "gemini-1.5-flash",
    "gemini-1.5-flash-latest",
    "gemini-pro",
    "gemini-1.0-pro",
  ];

  debugPrint("🔍 Testing ${keys.length} keys against ${models.length} models...\n");

  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    debugPrint("🔑 Key ${i + 1}: ${key.substring(0, 10)}...");

    bool keyWorked = false;

    for (var model in models) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
      );

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": "Hello"},
                ],
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("   ✅ SUCCESS with model: $model");
          keyWorked = true;
          // If we found a working model for this key, we can stop checking models for it
          // break;
        } else {
          // debugPrint("   ❌ Failed on $model: ${response.statusCode}");
          if (response.statusCode == 400 &&
              response.body.contains("API_KEY_INVALID")) {
            debugPrint("   ❌ Key Rejected: Invalid API Key");
            break; // Key is bad, no need to check other models
          }
        }
      } catch (e) {
        debugPrint("   ❌ Error: $e");
      }
    }

    if (!keyWorked) {
      debugPrint("   ⚠️ This key failed with all tested models.");
    }
    debugPrint("--------------------------------------------------");
  }
}
