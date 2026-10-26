import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_tutor_model.dart';
import 'ai_orchestrator_service.dart';

class AiTutorService {
  final AiOrchestratorService _orchestrator = AiOrchestratorService();

  /// Robust JSON extractor from AI output that strips markdown fences and surrounding text
  static dynamic extractJson(String text) {
    String cleaned = text.trim();

    // Remove markdown code fences if present
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Find the opening and closing brackets/braces
    final int firstCurly = cleaned.indexOf('{');
    final int lastCurly = cleaned.lastIndexOf('}');
    final int firstSquare = cleaned.indexOf('[');
    final int lastSquare = cleaned.lastIndexOf(']');

    try {
      return jsonDecode(cleaned);
    } catch (_) {
      // Try extracting bracketed substring
      if (firstCurly != -1 &&
          lastCurly != -1 &&
          (firstSquare == -1 || firstCurly < firstSquare)) {
        try {
          return jsonDecode(cleaned.substring(firstCurly, lastCurly + 1));
        } catch (_) {}
      } else if (firstSquare != -1 && lastSquare != -1) {
        try {
          return jsonDecode(cleaned.substring(firstSquare, lastSquare + 1));
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// 1. SUMMARIZE DOCUMENT
  Future<String> summarizeDocument({
    required String documentText,
    Uint8List? rawBytes,
    required String title,
  }) async {
    final prompt =
        """
You are an expert university academic professor and personal AI Tutor for tertiary institution students at Abdulkadir Kure University.
Your task is to analyze and provide a comprehensive, academically rigorous summary of the uploaded course material titled "$title".

CRITICAL INSTRUCTIONS:
1. Rely ONLY on the information presented in the provided course material. Do not hallucinate or invent external concepts.
2. Produce an in-depth, structured study guide designed specifically for university/tertiary students. Avoid shallow or trivial summaries.
3. Preserve all technical terminology, academic definitions, formulas/equations, principles, and theories.
4. Structure the summary cleanly in Markdown using the following exact organization:

# $title: Academic Comprehensive Summary

## 1. Executive Introduction & Overview
A clear overview of the course material, its central scope, and academic purpose.

## 2. Core Topics & In-Depth Explanations
For each major topic covered in the document:
### [Topic Name]
- **Detailed Explanation**: Thorough academic breakdown of the concept.
- **Key Principles & Mechanisms**: How it works and relationships with other topics.
- **Important Examples & Applications**: Concrete applications mentioned in the text.

## 3. Important Definitions & Terminology
A comprehensive glossary table or list of key terms defined in the material.

## 4. Fundamental Theories & Principles
The underlying laws, frameworks, or theoretical concepts presented.

## 5. Formulas, Equations & Calculations (if applicable)
Key mathematical or chemical equations, symbol meanings, and usage contexts. If not applicable to this subject, provide key qualitative frameworks.

## 6. Key Takeaways
Bullet points summarizing the essential facts students must remember for exams.

## 7. Exam Revision Checklist
A high-yield checklist of questions and topics students should test themselves on.

---
DOCUMENT CONTENT:
$documentText
""";

    try {
      final response = await _orchestrator.executeDirectPrompt(
        prompt,
        pdfBytes: rawBytes,
      );
      return response.trim();
    } catch (e) {
      debugPrint('Error in summarizeDocument: $e');
      throw Exception('Failed to generate document summary: $e');
    }
  }

  /// 2. GENERATE ESSAY QUESTIONS
  Future<List<AITutorQuestion>> generateEssayQuestions({
    required String documentText,
    Uint8List? rawBytes,
    required String title,
    int count = 10,
  }) async {
    final prompt =
        """
You are an academic examiner for tertiary institution students.
Based strictly on the provided document titled "$title", generate exactly $count high-quality university-level essay practice examination questions.

CRITICAL INSTRUCTIONS:
1. Questions must test higher-order cognitive domains (comprehension, critical analysis, application, synthesis, and evaluation).
2. Avoid shallow, one-word, or trivial questions.
3. For each question, provide an authoritative Expected Answer / Marking Guide and the Key Concepts being tested.
4. You MUST respond in pure JSON format only, with NO extra markdown text before or after the JSON.

Expected JSON format:
{
  "questions": [
    {
      "id": "1",
      "question": "Discuss the mechanism of ... and analyze its impact on ...",
      "marks": 10,
      "topic": "Topic Name",
      "expectedAnswer": "Comprehensive marking guide and expected points: 1. Definition ... 2. Detailed explanation ... 3. Critical discussion ...",
      "explanation": "This question tests understanding of ..."
    }
  ]
}

DOCUMENT CONTENT:
$documentText
""";

    try {
      final response = await _orchestrator.executeDirectPrompt(
        prompt,
        pdfBytes: rawBytes,
      );
      final decoded = extractJson(response);
      final List rawQuestions = decoded is Map
          ? (decoded['questions'] ?? [])
          : (decoded as List);

      final List<AITutorQuestion> questions = [];
      for (int i = 0; i < rawQuestions.length; i++) {
        final q = rawQuestions[i] as Map<String, dynamic>;
        questions.add(
          AITutorQuestion(
            id: q['id']?.toString() ?? '${i + 1}',
            question: q['question']?.toString() ?? 'Question ${i + 1}',
            options: const [],
            expectedAnswer: q['expectedAnswer']?.toString() ?? '',
            explanation: q['explanation']?.toString() ?? '',
            topic: q['topic']?.toString() ?? 'General Topic',
            marks: (q['marks'] is num) ? (q['marks'] as num).toInt() : 10,
          ),
        );
      }

      if (questions.isEmpty) {
        throw Exception('No questions could be parsed from the AI response.');
      }

      return questions;
    } catch (e) {
      debugPrint('Error in generateEssayQuestions: $e');
      throw Exception('Failed to generate essay questions: $e');
    }
  }

  /// 3. GRADE ESSAY ANSWERS
  Future<AITutorAttempt> gradeEssayAnswers({
    required List<AITutorQuestion> questions,
    required Map<String, String> studentAnswers,
    required String documentText,
    required String taskId,
  }) async {
    final List<Map<String, dynamic>> questionPayload = [];
    for (final q in questions) {
      final ans = studentAnswers[q.id]?.trim() ?? '(No answer provided)';
      questionPayload.add({
        'questionId': q.id,
        'question': q.question,
        'marks': q.marks,
        'expectedAnswer': q.expectedAnswer,
        'topic': q.topic,
        'studentAnswer': ans,
      });
    }

    final prompt =
        """
You are a rigorous tertiary university examiner evaluating a student's essay exam answers against the course syllabus and marking criteria.

STUDENT SUBMISSIONS:
${jsonEncode(questionPayload)}

SOURCE DOCUMENT REFERENCE:
$documentText

EVALUATION CRITERIA:
Evaluate each response on:
1. Accuracy & relevance to the question.
2. Completeness and mastery of key concepts.
3. Clarity and depth of explanation.
4. Penalize blank, copied, or factually incorrect points proportionally.

REQUIRED JSON FORMAT (Respond ONLY with valid JSON):
{
  "totalScore": 75,
  "maxScore": 100,
  "percentage": 75.0,
  "performance": "Good",
  "feedback": "Overall performance summary highlighting student's academic standing.",
  "recommendations": [
    "Specific actionable recommendation 1",
    "Specific actionable recommendation 2"
  ],
  "areasToRead": [
    "Topic X (Section on ...)",
    "Topic Y"
  ],
  "questionGradings": [
    {
      "questionId": "1",
      "score": 8,
      "maxScore": 10,
      "whatWentWell": "Clearly articulated the definition and primary equation.",
      "whatWasMissed": "Failed to mention the secondary boundary conditions.",
      "expectedAnswer": "...",
      "feedback": "Good attempt with minor gaps in technical depth.",
      "recommendation": "Review section on boundary constraints."
    }
  ]
}
""";

    try {
      final response = await _orchestrator.executeDirectPrompt(prompt);
      final decoded = extractJson(response);

      final totalScore = (decoded['totalScore'] as num?)?.toDouble() ?? 0.0;
      final maxScore =
          (decoded['maxScore'] as num?)?.toDouble() ??
          (questions.length * 10.0);
      final percentage =
          (decoded['percentage'] as num?)?.toDouble() ??
          (maxScore > 0 ? (totalScore / maxScore * 100) : 0.0);
      final performance =
          decoded['performance']?.toString() ??
          (percentage >= 70
              ? 'Excellent'
              : percentage >= 50
              ? 'Good'
              : 'Needs Improvement');
      final feedback = decoded['feedback']?.toString() ?? 'Grading completed.';
      final recommendations =
          (decoded['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final areasToRead =
          (decoded['areasToRead'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final questionGradings =
          (decoded['questionGradings'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          [];

      return AITutorAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: taskId,
        answers: studentAnswers,
        score: totalScore,
        maxScore: maxScore,
        percentage: percentage,
        performance: performance,
        feedback: feedback,
        recommendations: recommendations,
        areasToRead: areasToRead,
        questionGradings: questionGradings,
        submittedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error in gradeEssayAnswers: $e');
      throw Exception('Failed to grade essay examination: $e');
    }
  }

  /// 4. GENERATE OBJECTIVE (MCQ) QUESTIONS
  Future<List<AITutorQuestion>> generateObjectiveQuestions({
    required String documentText,
    Uint8List? rawBytes,
    required String title,
    int count = 10,
  }) async {
    final prompt =
        """
You are an academic examination author for tertiary university students.
Based strictly on the provided document titled "$title", generate exactly $count multiple-choice questions (Objective / CBT questions).

CRITICAL INSTRUCTIONS:
1. Each question must have exactly 4 plausible options (A, B, C, D).
2. There must be exactly ONE unambiguously correct answer.
3. The correctAnswer must be specified as an integer index (0 for Option A, 1 for Option B, 2 for Option C, 3 for Option D).
4. Provide a clear academic explanation of why the correct option is right and the others are incorrect.
5. Provide the specific topic or concept being tested.
6. Return pure JSON ONLY. No markdown wrapper outside the JSON.

Expected JSON format:
{
  "questions": [
    {
      "id": "1",
      "question": "Which of the following best defines ... in the context of ...?",
      "options": [
        "A. First plausible option",
        "B. Second plausible option",
        "C. Third plausible option",
        "D. Fourth plausible option"
      ],
      "correctAnswer": 0,
      "explanation": "Option A is correct because the material establishes that ...",
      "topic": "Topic Name"
    }
  ]
}

DOCUMENT CONTENT:
$documentText
""";

    try {
      final response = await _orchestrator.executeDirectPrompt(
        prompt,
        pdfBytes: rawBytes,
      );
      final decoded = extractJson(response);
      final List rawQuestions = decoded is Map
          ? (decoded['questions'] ?? [])
          : (decoded as List);

      final List<AITutorQuestion> questions = [];
      for (int i = 0; i < rawQuestions.length; i++) {
        final q = rawQuestions[i] as Map<String, dynamic>;
        final rawOptions =
            (q['options'] as List?)?.map((e) => e.toString()).toList() ?? [];

        // Ensure 4 options
        List<String> options = rawOptions;
        if (options.length < 4) {
          while (options.length < 4) {
            options.add('Option ${String.fromCharCode(65 + options.length)}');
          }
        }

        // Clean option prefixes if AI already added "A.", "B.", etc.
        options = options.map((opt) {
          return opt.replaceFirst(RegExp(r'^[A-Da-d][\.\)]\s*'), '').trim();
        }).toList();

        // Parse correct answer
        dynamic correctAns = q['correctAnswer'];
        int correctIndex = 0;
        if (correctAns is num) {
          correctIndex = correctAns.toInt();
        } else if (correctAns is String) {
          final upper = correctAns.trim().toUpperCase();
          if (upper.startsWith('A') || upper == '0') {
            correctIndex = 0;
          } else if (upper.startsWith('B') || upper == '1') {
            correctIndex = 1;
          } else if (upper.startsWith('C') || upper == '2') {
            correctIndex = 2;
          } else if (upper.startsWith('D') || upper == '3') {
            correctIndex = 3;
          }
        }

        if (correctIndex < 0 || correctIndex >= options.length) {
          correctIndex = 0;
        }

        questions.add(
          AITutorQuestion(
            id: q['id']?.toString() ?? '${i + 1}',
            question: q['question']?.toString() ?? 'Question ${i + 1}',
            options: options,
            correctAnswer: correctIndex,
            explanation: q['explanation']?.toString() ?? '',
            topic: q['topic']?.toString() ?? 'General Topic',
            marks: 1,
          ),
        );
      }

      if (questions.isEmpty) {
        throw Exception(
          'No objective questions could be parsed from AI response.',
        );
      }

      return questions;
    } catch (e) {
      debugPrint('Error in generateObjectiveQuestions: $e');
      throw Exception('Failed to generate objective questions: $e');
    }
  }

  /// 5. GRADE OBJECTIVE CBT ANSWERS & GENERATE AI RECOMMENDATIONS
  Future<AITutorAttempt> gradeObjectiveAnswers({
    required List<AITutorQuestion> questions,
    required Map<String, int> selectedAnswers,
    required String documentText,
    required String taskId,
  }) async {
    int correctCount = 0;
    final List<Map<String, dynamic>> questionGradings = [];
    final List<Map<String, dynamic>> missedQuestionsInfo = [];

    for (final q in questions) {
      final selected = selectedAnswers[q.id];
      final correct = (q.correctAnswer is num)
          ? (q.correctAnswer as num).toInt()
          : int.tryParse(q.correctAnswer.toString()) ?? 0;

      final bool isCorrect = selected != null && selected == correct;
      if (isCorrect) correctCount++;

      final grading = {
        'questionId': q.id,
        'question': q.question,
        'options': q.options,
        'selectedAnswerIndex': selected,
        'correctAnswerIndex': correct,
        'isCorrect': isCorrect,
        'explanation': q.explanation,
        'topic': q.topic,
      };
      questionGradings.add(grading);

      if (!isCorrect) {
        missedQuestionsInfo.add({
          'question': q.question,
          'selectedAnswer': selected != null && selected < q.options.length
              ? q.options[selected]
              : 'Unanswered',
          'correctAnswer': correct < q.options.length ? q.options[correct] : '',
          'topic': q.topic,
          'explanation': q.explanation,
        });
      }
    }

    final double totalQuestions = questions.length.toDouble();
    final double score = correctCount.toDouble();
    final double percentage = totalQuestions > 0
        ? (score / totalQuestions * 100)
        : 0.0;
    final String performance = percentage >= 80
        ? 'Excellent'
        : percentage >= 65
        ? 'Good'
        : percentage >= 50
        ? 'Average'
        : 'Needs Improvement';

    // Now query AI for personalized feedback and recommendations
    String feedback =
        'You answered $correctCount out of ${questions.length} questions correctly.';
    List<String> recommendations = [
      'Review topics with missed questions before your examination.',
    ];
    List<String> areasToRead = [];

    try {
      final prompt =
          """
You are an academic advisor reviewing a tertiary student's objective CBT test results.
The student scored $correctCount/${questions.length} (${percentage.toStringAsFixed(1)}%). Performance: $performance.

MISSED QUESTIONS AND TOPICS:
${jsonEncode(missedQuestionsInfo)}

SOURCE DOCUMENT REFERENCE:
$documentText

Based on the topics missed, provide personalized diagnostic feedback.
Return pure JSON ONLY:
{
  "feedback": "Diagnostic summary of performance and conceptual grasp.",
  "recommendations": [
    "Specific revision recommendation 1",
    "Specific revision recommendation 2"
  ],
  "areasToRead": [
    "Specific topic or chapter name to read",
    "Another specific concept"
  ]
}
""";

      final response = await _orchestrator.executeDirectPrompt(prompt);
      final decoded = extractJson(response);
      if (decoded is Map) {
        if (decoded['feedback'] != null) {
          feedback = decoded['feedback'].toString();
        }
        if (decoded['recommendations'] is List) {
          recommendations = (decoded['recommendations'] as List)
              .map((e) => e.toString())
              .toList();
        }
        if (decoded['areasToRead'] is List) {
          areasToRead = (decoded['areasToRead'] as List)
              .map((e) => e.toString())
              .toList();
        }
      }
    } catch (e) {
      debugPrint(
        'Warning: Could not fetch AI recommendations for objective test: $e',
      );
      // If AI fails, derive topics from missed questions
      final uniqueTopics = missedQuestionsInfo
          .map((m) => m['topic']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      if (uniqueTopics.isNotEmpty) {
        areasToRead = uniqueTopics;
        recommendations = uniqueTopics
            .map((t) => 'Revisit material covering $t')
            .toList();
      }
    }

    return AITutorAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      answers: selectedAnswers.map((k, v) => MapEntry(k, v)),
      score: score,
      maxScore: totalQuestions,
      percentage: percentage,
      performance: performance,
      feedback: feedback,
      recommendations: recommendations,
      areasToRead: areasToRead,
      questionGradings: questionGradings,
      submittedAt: DateTime.now(),
    );
  }
}
