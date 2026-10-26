import 'package:flutter/material.dart';
import '../../models/ai_tutor_model.dart';
import '../../services/ai_tutor_service.dart';
import '../../services/ai_tutor_storage_service.dart';
import '../../services/pdf_extractor_service.dart';

class AddTaskDialog extends StatefulWidget {
  final AITutorDocument document;

  const AddTaskDialog({super.key, required this.document});

  static Future<bool?> show(BuildContext context, AITutorDocument document) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskDialog(document: document),
    );
  }

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final AiTutorService _aiTutorService = AiTutorService();

  // Dropdown options matching specifications exactly
  static const String optionSummarize = 'Summarize';
  static const String optionEssay = 'Practice Questions (Essay)';
  static const String optionObjective = 'Practice Questions (Objective)';

  final List<String> _taskTypeOptions = [
    optionSummarize,
    optionEssay,
    optionObjective,
  ];

  String _selectedTaskType = optionSummarize;
  bool _isGenerating = false;
  String _loadingMessage = 'AI is studying your document...';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();

    setState(() {
      _isGenerating = true;
      _loadingMessage = 'AI is studying your document...';
    });

    try {
      // 1. Extract and process PDF content
      final ExtractedPdfData pdfData =
          await PdfExtractorService.extractFromPath(widget.document.pdfPath);

      // Check if text is present
      final hasText = pdfData.text.trim().isNotEmpty;
      final rawBytes = pdfData.rawBytes;

      if (!hasText && rawBytes.isEmpty) {
        throw Exception('The PDF contains no readable text or content.');
      }

      setState(() {
        _loadingMessage = 'Generating your learning task with AI...';
      });

      // 2. Dispatch to existing Gemini/AKUM AI Tutor service
      if (_selectedTaskType == optionSummarize) {
        final summaryMarkdown = await _aiTutorService.summarizeDocument(
          documentText: pdfData.text,
          rawBytes: pdfData.isScannedOrEmptyText ? rawBytes : null,
          title: widget.document.title,
        );

        await AITutorStorageService.addTask(
          widget.document,
          title: title,
          type: kTaskTypeSummarize,
          status: kTaskStatusCompleted,
          generatedContent: summaryMarkdown,
        );
      } else if (_selectedTaskType == optionEssay) {
        final questions = await _aiTutorService.generateEssayQuestions(
          documentText: pdfData.text,
          rawBytes: pdfData.isScannedOrEmptyText ? rawBytes : null,
          title: widget.document.title,
          count: 10,
        );

        final task = await AITutorStorageService.addTask(
          widget.document,
          title: title,
          type: kTaskTypeEssay,
          status: kTaskStatusCompleted,
        );

        task.questions = questions;
        await widget.document.save();
      } else if (_selectedTaskType == optionObjective) {
        final questions = await _aiTutorService.generateObjectiveQuestions(
          documentText: pdfData.text,
          rawBytes: pdfData.isScannedOrEmptyText ? rawBytes : null,
          title: widget.document.title,
          count: 10,
        );

        final task = await AITutorStorageService.addTask(
          widget.document,
          title: title,
          type: kTaskTypeObjective,
          status: kTaskStatusCompleted,
        );

        task.questions = questions;
        await widget.document.save();
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "$title" generated successfully!'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });

      String userMessage = 'AI Tutor could not generate this task right now.';
      final errString = e.toString().toLowerCase();

      if (errString.contains('internet') ||
          errString.contains('socket') ||
          errString.contains('network')) {
        userMessage =
            'AI Tutor could not generate this task right now. Please check your internet connection and try again.';
      } else if (errString.contains('empty') || errString.contains('0 bytes')) {
        userMessage =
            'The selected document is empty or unreadable. Please check your PDF file.';
      } else if (errString.contains('quota') ||
          errString.contains('rate limit')) {
        userMessage =
            'AI capacity limit reached. Please wait a moment and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          widget.document.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!_isGenerating)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Task Title
              const Text(
                'Task Title',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                enabled: !_isGenerating,
                decoration: InputDecoration(
                  hintText: 'e.g., Introduction to Trigonometry Summary',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.title,
                    color: Colors.green,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Task Type Dropdown
              const Text(
                'Task Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedTaskType,
                items: _taskTypeOptions.map((option) {
                  IconData icon = Icons.description_outlined;
                  if (option == optionEssay) icon = Icons.edit_note_rounded;
                  if (option == optionObjective) icon = Icons.quiz_outlined;

                  return DropdownMenuItem<String>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isGenerating
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTaskType = val;
                          });
                        }
                      },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Loading State Display
              if (_isGenerating) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _loadingMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Create Task Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _handleCreateTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.shade200,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: _isGenerating
                      ? const Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Text(
                          'Create Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
