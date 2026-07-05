import 'package:flutter/foundation.dart';
import 'ai_providers/ai_provider.dart';
import 'ai_providers/gemini_ai_provider.dart';
import 'ai_providers/groq_ai_provider.dart';

import 'ai_providers/sambanova_ai_provider.dart';

import 'local_school_qa_service.dart';

class AiOrchestratorService {
  late final List<AiProvider> _providers;
  int _currentProviderIndex = 0;

  AiOrchestratorService() {
    // Initialize providers in priority order
    _providers = [
      GeminiAiProvider(), // 1. Gemini (Primary)
      GroqAiProvider(), // 2. Groq (Secondary)
      SambanovaAiProvider(), // 3. SambaNova (Tertiary)
    ];
  }

  void init(String systemPrompt, String compactSystemPrompt) {
    for (final provider in _providers) {
      try {
        if (provider.id == 'gemini') {
          provider.init(systemPrompt);
        } else {
          // Fallback providers (Groq, SambaNova) get the compact prompt
          // to avoid TPM limits.
          provider.init(compactSystemPrompt);
        }
      } catch (e) {
        debugPrint("Failed to init provider ${provider.id}: $e");
      }
    }
  }

  Future<String> sendMessage(String message) async {
    // Try providers starting from the current active one
    // We iterate through all providers starting from _currentProviderIndex
    // If all fail, we reset index to 0 and throw exception.

    // Actually, simple logic: Try current. If fail, move next.
    // If we reach end, wrap around? Or stop?
    // Requirement: "Tries providers in priority order ... Automatically switches to next provider"

    // We should probably try to respect the priority order, but if one fails permanently (quota), disable it?
    // For now, let's just cycle through them for the current request if one fails.

    // We loop through the providers list starting from _currentProviderIndex
    // If a provider fails, we increment _currentProviderIndex (failover) and try next.
    // We stop when we have tried all providers.

    int attempts = 0;
    final totalProviders = _providers.length;

    while (attempts < totalProviders) {
      final provider = _providers[_currentProviderIndex];
      debugPrint("🤖 Orchestrator: Attempting to use ${provider.id}...");

      try {
        final response = await provider.sendMessage(message);
        debugPrint("✅ Orchestrator: Success with ${provider.id}");
        return response;
      } catch (e) {
        debugPrint("❌ Orchestrator: ${provider.id} failed: $e");

        // Check if we should switch
        // "Quota exceeded", "Network error", "Rate limit", "Auth error"
        // If it's a temporary error we might retry, but requirement says "Automatically switches"
        // So we switch.

        _currentProviderIndex = (_currentProviderIndex + 1) % _providers.length;
        attempts++;

        debugPrint(
          "🔄 Orchestrator: Switching to next provider (Index: $_currentProviderIndex)",
        );
      }
    }

    debugPrint(
      "⚠️ Orchestrator: All providers failed. Switching to Local Fallback.",
    );

    // Fallback to local school knowledge service (LocalSchoolQaService)
    try {
      final localResponse = await LocalSchoolQaService().tryAnswer(message);
      if (localResponse != null) {
        debugPrint("✅ Orchestrator: Local Fallback responded.");
        return "$localResponse\n\n(Offline Mode)";
      } else {
        return "I can currently answer only questions related to the school. This information is not available in the school database.";
      }
    } catch (e) {
      debugPrint("❌ Orchestrator: Local Fallback failed: $e");
      return "I am currently offline and could not find an answer in my local database.";
    }
  }

  String getCurrentProviderName() {
    return _providers[_currentProviderIndex].id;
  }
}
