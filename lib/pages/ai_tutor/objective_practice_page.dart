import 'package:flutter/material.dart';
import '../../models/ai_tutor_model.dart';
import '../../services/ai_tutor_service.dart';
import '../../services/ai_tutor_storage_service.dart';
import '../../services/pdf_extractor_service.dart';
import 'objective_results_page.dart';

class ObjectivePracticePage extends StatefulWidget {
  final AITutorDocument document;
  final AITutorTask task;

  const ObjectivePracticePage({
    super.key,
    required this.document,
    required this.task,
  });

  @override
  State<ObjectivePracticePage> createState() => _ObjectivePracticePageState();
}

class _ObjectivePracticePageState extends State<ObjectivePracticePage> {
  final AiTutorService _aiTutorService = AiTutorService();
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = {};
  bool _isGrading = false;

  void _selectOption(String questionId, int optionIndex) {
    setState(() {
      _selectedAnswers[questionId] = optionIndex;
    });
  }

  Future<void> _submitExamination() async {
    final questions = widget.task.questions;
    final answeredCount = _selectedAnswers.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Objective Test?'),
        content: Text(
          'You have answered $answeredCount of ${questions.length} questions.\n\nAre you sure you want to submit your test for scoring and AI diagnosis?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Review Questions'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Test'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isGrading = true;
    });

    try {
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

      final attempt = await _aiTutorService.gradeObjectiveAnswers(
        questions: questions,
        selectedAnswers: _selectedAnswers,
        documentText: contextText,
        taskId: widget.task.id,
      );

      // Save attempt
      await AITutorStorageService.recordAttempt(
        widget.document,
        widget.task.id,
        attempt,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ObjectiveResultsPage(
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
          content: Text('Grading error: $e'),
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
                  final isAnswered = _selectedAnswers.containsKey(q.id);
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
          title: const Text('Objective Practice'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No objective questions found in this task.'),
        ),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final selectedOption = _selectedAnswers[currentQuestion.id];
    final isLastQuestion = _currentIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Objective Practice (CBT)',
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

              // Header bar: Counter and Topic
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
                    if (currentQuestion.topic.isNotEmpty)
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
                          currentQuestion.topic,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Question prompt and Options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
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
                        'Select the correct option:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Options
                      for (
                        int i = 0;
                        i < currentQuestion.options.length;
                        i++
                      ) ...[
                        _buildOptionItem(
                          index: i,
                          prefix: String.fromCharCode(65 + i),
                          text: currentQuestion.options[i],
                          isSelected: selectedOption == i,
                          onTap: () => _selectOption(currentQuestion.id, i),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Navigation bar
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

                      // Next or Submit
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
                            isLastQuestion ? 'Submit Test' : 'Next Question',
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

          // Grading overlay
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
                        'AI is analyzing your performance...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Calculating your score and preparing diagnostic recommendations.',
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

  Widget _buildOptionItem({
    required int index,
    required String prefix,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green : Colors.grey.shade100,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade400,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                prefix,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.green.shade900 : Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.green : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
