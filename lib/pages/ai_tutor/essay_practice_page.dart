import 'package:flutter/material.dart';
import '../../models/ai_tutor_model.dart';
import '../../services/ai_tutor_service.dart';
import '../../services/ai_tutor_storage_service.dart';
import '../../services/pdf_extractor_service.dart';
import 'essay_results_page.dart';

class EssayPracticePage extends StatefulWidget {
  final AITutorDocument document;
  final AITutorTask task;

  const EssayPracticePage({
    super.key,
    required this.document,
    required this.task,
  });

  @override
  State<EssayPracticePage> createState() => _EssayPracticePageState();
}

class _EssayPracticePageState extends State<EssayPracticePage> {
  final AiTutorService _aiTutorService = AiTutorService();
  int _currentIndex = 0;
  final Map<String, TextEditingController> _controllers = {};
  bool _isGrading = false;

  @override
  void initState() {
    super.initState();
    final questions = widget.task.questions;
    for (final q in questions) {
      _controllers[q.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitExamination() async {
    final questions = widget.task.questions;
    final answeredCount = _controllers.values
        .where((c) => c.text.trim().isNotEmpty)
        .length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Essay Practice?'),
        content: Text(
          'You have completed $answeredCount of ${questions.length} questions.\n\nAre you sure you want to submit your responses for AI grading?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isGrading = true;
    });

    try {
      // Gather student answers
      final Map<String, String> studentAnswers = {};
      for (final q in questions) {
        studentAnswers[q.id] = _controllers[q.id]?.text.trim() ?? '';
      }

      // Extract document text for grading context
      String contextText = widget.task.generatedContent;
      if (contextText.isEmpty) {
        try {
          final extracted = await PdfExtractorService.extractFromPath(
            widget.document.pdfPath,
          );
          contextText = extracted.text;
        } catch (_) {
          contextText = widget.document.title;
        }
      }

      final attempt = await _aiTutorService.gradeEssayAnswers(
        questions: questions,
        studentAnswers: studentAnswers,
        documentText: contextText,
        taskId: widget.task.id,
      );

      // Save attempt into storage
      await AITutorStorageService.recordAttempt(
        widget.document,
        widget.task.id,
        attempt,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EssayResultsPage(
            document: widget.document,
            task: widget.task,
            attempt: attempt,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGrading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Grading Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showQuestionPalette() {
    final questions = widget.task.questions;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Question Navigator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(questions.length, (idx) {
                  final q = questions[idx];
                  final isAnswered =
                      _controllers[q.id]?.text.trim().isNotEmpty ?? false;
                  final isCurrent = idx == _currentIndex;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _currentIndex = idx;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.green
                            : isAnswered
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? Colors.green
                              : isAnswered
                              ? Colors.green.shade400
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : isAnswered
                              ? Colors.green.shade800
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.task.questions;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Essay Practice'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No questions found in this practice task.'),
        ),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final currentController = _controllers[currentQuestion.id]!;
    final isLastQuestion = _currentIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Essay Practice Exam',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.document.title,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Question Navigator',
            onPressed: _showQuestionPalette,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / questions.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 4,
              ),

              // Header bar with Question counter and Marks
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '${currentQuestion.marks} Marks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        if (currentQuestion.topic.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentQuestion.topic,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Question body and input
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question prompt card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          currentQuestion.question,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Your Detailed Answer:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Answer text field
                      TextFormField(
                        controller: currentController,
                        maxLines: 12,
                        decoration: InputDecoration(
                          hintText:
                              'Write your answer here in detail. Explain principles, definitions, mechanisms, and key points...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation controls bottom bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Previous button
                      OutlinedButton(
                        onPressed: _currentIndex > 0
                            ? () {
                                setState(() {
                                  _currentIndex--;
                                });
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 12),

                      // Next or Submit button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastQuestion) {
                              _submitExamination();
                            } else {
                              setState(() {
                                _currentIndex++;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLastQuestion
                                ? Colors.green.shade800
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isLastQuestion
                                ? 'Submit Examination'
                                : 'Next Question',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay during AI grading
          if (_isGrading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AI Tutor is grading your answers...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Evaluating accuracy, depth, understanding, and missing points against course material.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
