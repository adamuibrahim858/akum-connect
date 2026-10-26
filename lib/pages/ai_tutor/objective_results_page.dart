import 'package:flutter/material.dart';
import '../../models/ai_tutor_model.dart';

class ObjectiveResultsPage extends StatelessWidget {
  final AITutorDocument document;
  final AITutorTask task;
  final AITutorAttempt attempt;

  const ObjectiveResultsPage({
    super.key,
    required this.document,
    required this.task,
    required this.attempt,
  });

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final questions = task.questions;
    final totalQuestions = questions.length;
    final gradings = attempt.questionGradings;

    int correctCount = 0;
    int wrongCount = 0;
    for (final g in gradings) {
      if (g['isCorrect'] == true) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    final scoreColor = _getScoreColor(attempt.percentage);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Objective Practice Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Score Badge
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withValues(alpha: 0.1),
                      border: Border.all(color: scoreColor, width: 4),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${attempt.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '$correctCount / $totalQuestions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Performance: ${attempt.performance}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Total',
                        '$totalQuestions',
                        Colors.black87,
                      ),
                      _buildStatColumn(
                        'Correct',
                        '$correctCount',
                        Colors.green,
                      ),
                      _buildStatColumn('Wrong', '$wrongCount', Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AI Recommendation Box
            if (attempt.feedback.isNotEmpty ||
                attempt.recommendations.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.green.shade800,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Diagnostic Recommendation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      if (attempt.feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          attempt.feedback,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade900,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (attempt.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (final rec in attempt.recommendations)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade900,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Areas to Read More
            if (attempt.areasToRead.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: Colors.amber.shade900,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Areas to Read More',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final area in attempt.areasToRead)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_right,
                                size: 18,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  area,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Detailed Questions Review Header
            const Text(
              'Questions Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Question by question list
            for (int i = 0; i < questions.length; i++) ...[
              _buildQuestionReviewCard(i, questions[i], gradings),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuestionReviewCard(
    int index,
    AITutorQuestion question,
    List<Map<String, dynamic>> gradings,
  ) {
    final grading = gradings.firstWhere(
      (g) => g['questionId']?.toString() == question.id,
      orElse: () => <String, dynamic>{},
    );

    final bool isCorrect = grading['isCorrect'] == true;
    final int? selectedIndex = grading['selectedAnswerIndex'] as int?;
    final int correctIndex =
        (grading['correctAnswerIndex'] as int?) ??
        ((question.correctAnswer is num)
            ? (question.correctAnswer as num).toInt()
            : 0);

    final options = question.options;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isCorrect
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: isCorrect
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (question.topic.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.topic,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Options list
            for (int optIdx = 0; optIdx < options.length; optIdx++) ...[
              _buildOptionTile(
                prefix: String.fromCharCode(65 + optIdx),
                text: options[optIdx],
                isCorrectOption: optIdx == correctIndex,
                isSelectedByStudent: optIdx == selectedIndex,
              ),
              const SizedBox(height: 6),
            ],

            // Explanation
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.explanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String prefix,
    required String text,
    required bool isCorrectOption,
    required bool isSelectedByStudent,
  }) {
    Color bgColor = Colors.grey.shade50;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;
    IconData? icon;
    Color? iconColor;

    if (isCorrectOption) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isSelectedByStudent && !isCorrectOption) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade900;
      icon = Icons.cancel;
      iconColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrectOption
                  ? Colors.green
                  : isSelectedByStudent
                  ? Colors.red
                  : Colors.grey.shade300,
            ),
            alignment: Alignment.center,
            child: Text(
              prefix,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isCorrectOption || isSelectedByStudent)
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 6),
            Icon(icon, size: 18, color: iconColor),
          ],
        ],
      ),
    );
  }
}
