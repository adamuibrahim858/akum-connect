import 'package:flutter/foundation.dart';
import 'local_school_qa_service.dart';

class LocalSchoolOnlyChatService {
  final LocalSchoolQaService _localQa = LocalSchoolQaService();

  static const List<String> _greetings = [
    'hi',
    'hello',
    'hey',
    'good morning',
    'good afternoon',
    'good evening',
    'salam',
    'assalamu alaikum',
  ];

  static const String _greetingResponse =
      "Hello! I am the official AI Assistant for Abdulkadir Kure University, Minna. "
      "I can help you with information about faculties, departments, courses, management, and school buildings. "
      "How can I assist you with school information today?";

  static const String _notFoundResponse =
      "Sorry, I do not have that information in the school database.";

  Future<void> init() async {
    await _localQa.loadData();
  }

  /// Checks if the message is a greeting or can be answered locally.
  /// Returns a specific response string if handled locally, or NULL if it should go to AI.
  Future<String?> tryHandleLocally(String message) async {
    final cleanMsg = message.trim().toLowerCase();

    // 1. Check Greeting
    for (var g in _greetings) {
      if (cleanMsg == g || cleanMsg.startsWith("$g ")) {
        return _greetingResponse;
      }
    }

    // 2. Check Local Exact/Fuzzy Match (High Confidence)
    // We strictly use the local QA service to see if we have a direct answer.
    // If the confidence is very high, we return it to save AI calls.
    final localAnswer = await _localQa.tryAnswer(message);
    if (localAnswer != null) {
      debugPrint("🤖 StrictChat: Answered locally.");
      return localAnswer;
    }

    // 3. If not found locally, we allow the AI to try answering using the context.
    // The requirement says "If NOT found -> return NOT FOUND".
    // BUT checking simple regex vs "Not Found" is risky because the user might ask "Who runs the math department?"
    // and our regex might fail, but the AI context has the info.
    // So we return NULL here to signal "Pass to AI (with Context)".
    // The AI itself has the instruction to say "Sorry..." if it doesn't know.

    return null;
  }

  Future<String> getSystemPrompt() async {
    final schoolsData = await _localQa.getFullContext();
    return """
You are the official AI Assistant for Abdulkadir Kure University, Minna.

You are STRICTLY LIMITED to answering questions using ONLY the information provided below.

You are NOT allowed to:
- Use general knowledge
- Use internet knowledge
- Answer educational theory
- Answer non-school questions
- Guess or invent any information

Your ONLY source of truth is the school data provided below.

================================================
SCHOOL DATA CONTEXT
================================================
$schoolsData
================================================

================================================
GREETING & IDENTITY RULES
================================================
If the user says a greeting, respond EXACTLY:
"$_greetingResponse"

================================================
STRICT DATA RULES
================================================
- Use ONLY the provided school data context.
- Do NOT guess missing data.

================================================
NOT FOUND RULE (SCHOOL QUESTION BUT NOT IN DATABASE)
================================================
If the user asks about the school BUT the information is NOT in the data above, respond EXACTLY:
"$_notFoundResponse"

================================================
OUT-OF-SCOPE RULE (GENERAL KNOWLEDGE / TUTORING)
================================================
If the user asks a general academic question (e.g., "What is a noun?", "Explain calculus"), you MAY answer it.
- Act as a helpful University Tutor.
- Be educational, clear, and student-friendly.
- Do NOT mention the school database for general questions.

HOWEVER, if the user asks about the SCHOOL (e.g., "Does AKUM have a law faculty?"), you must Use ONLY the provided school data context.
- If the school data doesn't have the answer, respond: "$_notFoundResponse"

================================================
ANSWER STYLE
================================================
- Professional, Polite, and Encouraging.
- For school questions: Short, accurate, and official.
- For tutoring questions: Detailed, explanatory, and helpful.
- No emojis.
    """;
  }
}
