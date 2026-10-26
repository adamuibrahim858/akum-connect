import 'package:flutter/material.dart';
import '../../models/ai_tutor_model.dart';

class EssayResultsPage extends StatelessWidget {
  final AITutorDocument document;
  final AITutorTask task;
  final AITutorAttempt attempt;

  const EssayResultsPage({
    super.key,
    required this.document,
    required this.task,
    required this.attempt,
  });

  Color _getScoreColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final questions = task.questions;
    final totalQuestions = questions.length;
    final gradings = attempt.questionGradings;

    // Count strong vs needs improvement
    int strongCount = 0;
    int needsImprovementCount = 0;
    for (final g in gradings) {
      final score = (g['score'] as num?)?.toDouble() ?? 0.0;
      final maxScore = (g['maxScore'] as num?)?.toDouble() ?? 10.0;
      if (maxScore > 0 && (score / maxScore) >= 0.6) {
        strongCount++;
      } else {
        needsImprovementCount++;
      }
    }

    final scoreColor = _getScoreColor(attempt.percentage);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Essay Practice Result',
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
            // Overall Score Card
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
                  // Score circle badge
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
                            'Score: ${attempt.score.toStringAsFixed(0)}/${attempt.maxScore.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
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
                        'Questions',
                        '$totalQuestions',
                        Colors.black87,
                      ),
                      _buildStatColumn('Strong', '$strongCount', Colors.green),
                      _buildStatColumn(
                        'Needs Work',
                        '$needsImprovementCount',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AI Feedback Overview
            if (attempt.feedback.isNotEmpty) ...[
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
                            Icons.psychology,
                            color: Colors.green.shade800,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Tutor Evaluation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        attempt.feedback,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Areas to Read More / Recommendations
            if (attempt.areasToRead.isNotEmpty ||
                attempt.recommendations.isNotEmpty) ...[
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
                            Icons.auto_stories,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  area,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (attempt.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final rec in attempt.recommendations)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('👉 ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
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
              const SizedBox(height: 20),
            ],

            // Section Header
            const Text(
              'Detailed Question Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Per question breakdown
            for (int i = 0; i < questions.length; i++) ...[
              _buildQuestionGradingCard(i, questions[i], gradings),
              const SizedBox(height: 14),
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

  Widget _buildQuestionGradingCard(
    int index,
    AITutorQuestion question,
    List<Map<String, dynamic>> gradings,
  ) {
    // Find grading for question
    final grading = gradings.firstWhere(
      (g) => g['questionId']?.toString() == question.id,
      orElse: () => <String, dynamic>{},
    );

    final score = (grading['score'] as num?)?.toDouble() ?? 0.0;
    final maxScore =
        (grading['maxScore'] as num?)?.toDouble() ?? question.marks.toDouble();
    final studentAnswer =
        attempt.answers[question.id]?.toString().trim() ?? '(No answer)';
    final expectedAnswer =
        grading['expectedAnswer']?.toString().isNotEmpty == true
        ? grading['expectedAnswer'].toString()
        : question.expectedAnswer;
    final whatWentWell = grading['whatWentWell']?.toString() ?? '';
    final whatWasMissed = grading['whatWasMissed']?.toString() ?? '';
    final feedback = grading['feedback']?.toString() ?? '';
    final recommendation = grading['recommendation']?.toString() ?? '';

    final bool isStrong = maxScore > 0 && (score / maxScore) >= 0.6;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isStrong ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: isStrong
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Text(
            'Q${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStrong ? Colors.green.shade800 : Colors.orange.shade900,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isStrong
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Score: ${score.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isStrong
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                question.topic,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Question Text
                const Text(
                  'Full Question:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Student Answer
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
                        'Your Answer:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentAnswer.isNotEmpty ? studentAnswer : '(Blank)',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Expected Answer
                if (expectedAnswer.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Marking Criteria / Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expectedAnswer,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade900,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // What went well & missed
                if (whatWentWell.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Well Done: $whatWentWell',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (whatWasMissed.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cancel,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gaps: $whatWasMissed',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (feedback.isNotEmpty) ...[
                  Text(
                    'Feedback: $feedback',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (recommendation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Recommendation: $recommendation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
