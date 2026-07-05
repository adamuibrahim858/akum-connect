import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'school_knowledge_service.dart';
import 'ai_orchestrator_service.dart';

class AiService {
  final AiOrchestratorService _orchestrator = AiOrchestratorService();
  bool _isInitialized = false;

  AiService() {
    _init();
  }

  Future<void> _init() async {
    // Ensure school knowledge is loaded
    await SchoolKnowledgeService().loadData();

    // Context for the AI
    // final contextData = SchoolKnowledgeService().context; // This line is no longer needed

    // 1. Full JSON Prompt for Gemini (Deep Reasoning)
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
${jsonEncode(SchoolKnowledgeService().getFullDataAsJson())}
""";

    // 2. Compact Prompt for Groq/SambaNova (Rate Limit Optimized)
    final String compactSystemPrompt =
        """
You are the official AI assistant for Abdulkadir Kure University.
Answer questions based on the following summary Context.

CONTEXT:
${SchoolKnowledgeService().context}

INSTRUCTIONS:
- Answer confidently if found in Context.
- If not found, use general knowledge but warn: "⚠️ Note: This information is not from the official school database..."
- Do not hallucinate.
""";

    _orchestrator.init(fullSystemPrompt, compactSystemPrompt);

    _isInitialized = true;
    debugPrint("✅ AiService: AI-First Architecture Initialized.");
  }

  /// Sends a message and returns the full text response.
  Future<String?> sendMessage(String message) async {
    if (!_isInitialized) await _init();

    // AI-First Rule: Always try AI Orchestrator first.
    // The Orchestrator handles quota checks and Local Fallback if necessary.
    return await _orchestrator.sendMessage(message);
  }

  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) await _init();

    try {
      // Logic is handled by orchestrator, but orchestrator currently returns Future<String>.
      // To support streaming, we would need the providers to support streaming.
      // For now, we await the full response and yield it.

      final response = await _orchestrator.sendMessage(message);
      yield response;
    } catch (e) {
      debugPrint("❌ Error during stream processing: $e");
      yield "An error occurred while processing your request.";
    }
  }
}
