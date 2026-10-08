import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Mocking DotEnv since we can't easily use the flutter one in pure dart without setup
class MockDotEnv {
  Map<String, String> env = {};
  Future<void> load() async {
    final file = File('.env');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (var line in lines) {
        if (line.contains('=')) {
          final parts = line.split('=');
          env[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
  }
}

Future<void> main() async {
  debugPrint("🔍 Loading environment...");
  final dotenv = MockDotEnv();
  await dotenv.load();

  debugPrint("📂 Loading School Data from assets...");
  final schoolDataStr = await File(
    'assets/school data/school_data.json',
  ).readAsString();
  final examDataStr = await File(
    'assets/school data/examination.json',
  ).readAsString();
  final aboutStr = await File('assets/school data/about.txt').readAsString();
  final aboutAppStr = await File(
    'assets/school data/about_app.txt',
  ).readAsString();

  final fullData = {
    "school_data": jsonDecode(schoolDataStr),
    "examination_data": jsonDecode(examDataStr),
    "about_text": aboutStr,
    "about_app_text": aboutAppStr,
    "app_version": "1.0.0+1 (Debug)",
  };

  // 2. Compact Prompt for Groq/SambaNova
  final String compactSystemPrompt =
      """
You are the official AI assistant for Abdulkadir Kure University.
Answer questions based on the following summary Context.

CONTEXT:
SCHOOL: Abdulkadir Kure University
LOCATION: Minna
$aboutStr
[Summary of Faculties/Departments would go here in real service]
VC/MANAGEMENT:
- Vice Chancellor: Prof. Aliyu Muhammad Paiko
- Registrar: Dr. Garba Abdullahi
ABOUT APP:
$aboutAppStr

INSTRUCTIONS:
- Answer confidently if found in Context.
- If not found, use general knowledge but warn: "⚠️ Note: This information is not from the official school database..."
- Do not hallucinate.
""";

  debugPrint("🤖 Compact Prompt Length: ${compactSystemPrompt.length} chars");

  final String fullSystemPrompt =
      """
You are the official AI assistant for Abdulkadir Kure University.
You are given access to school files located in assets/school data/.

1. FIRST, search the "SCHOOL DATA CLOUD" above.
   - Use deeply nested keys (e.g., academic_structure -> faculties -> departments -> programmes).
   - Reason across relationships (if A is in B, and B is in C, then A is in C).
   - Check "about_app_text" for questions about the specific mobile application, its developer, or features.
   - If the answer is found in the school/app data, answer CONFIDENTLY as the official AI. Do NOT mention "database" or "JSON".

2. IF THE ANSWER IS NOT IN THE SCHOOL DATA:
   - You may answer using general academic knowledge.
   - BUT you MUST prepend this EXACT warning:
     "⚠️ Note: This information is not from the official school database, but from general academic knowledge and may not be specific to Abdulkadir Kure University."
   - Then provide the helpful general answer.

3. DO NOT hallucinate school-specific facts (like names, dates, or fees) if they are not in the file.

---
SCHOOL DATA CLOUD (JSON format):
${jsonEncode(fullData)}
""";

  debugPrint("🤖 Full System Prompt Length: ${fullSystemPrompt.length} chars");

  // Test Groq with Compact Prompt
  await testProvider(
    "Groq",
    "https://api.groq.com/openai/v1/chat/completions",
    dotenv.env['GROQ_API_KEY']!,
    "llama-3.1-8b-instant",
    compactSystemPrompt,
    "Who is the Registrar?",
  );

  // Test SambaNova with Compact Prompt
  await testProvider(
    "SambaNova",
    "https://api.sambanova.ai/v1/chat/completions",
    dotenv.env['SAMBANOVA_API_KEY']!,
    "Meta-Llama-3.1-8B-Instruct",
    compactSystemPrompt,
    "Who is the Registrar?",
  );
}

Future<void> testProvider(
  String name,
  String url,
  String key,
  String model,
  String system,
  String userQuery,
) async {
  debugPrint("\n---------------------------------------------------");
  debugPrint("🧪 Testing $name ($model)...");

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {"role": "system", "content": system},
          {"role": "user", "content": userQuery},
        ],
        'temperature': 0.1, // Low temp for factual answers
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'];
      debugPrint("✅ Response:\n$content");
    } else {
      debugPrint("❌ Error ${response.statusCode}: ${response.body}");
    }
  } catch (e) {
    debugPrint("❌ Exception: $e");
  }
}
