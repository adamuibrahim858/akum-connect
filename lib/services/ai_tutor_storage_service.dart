import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_tutor_model.dart';

class AITutorStorageService {
  static const String boxName = 'ai_tutor_documents';

  static Box<AITutorDocument> getBox() {
    return Hive.box<AITutorDocument>(boxName);
  }

  /// Adds a new document after safely copying the PDF file into application storage
  static Future<AITutorDocument> addDocument({
    required String title,
    required String originalFileName,
    required String sourceFilePath,
  }) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    // Persist file into app's documents directory so it isn't lost if cache is purged
    String savedFilePath = sourceFilePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final aiTutorDir = Directory('${appDir.path}/ai_tutor_docs');
      if (!await aiTutorDir.exists()) {
        await aiTutorDir.create(recursive: true);
      }

      final extension = originalFileName.contains('.')
          ? originalFileName.substring(originalFileName.lastIndexOf('.'))
          : '.pdf';
      final newFileName = 'doc_$id$extension';
      final savedFile = File('${aiTutorDir.path}/$newFileName');

      final sourceFile = File(sourceFilePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(savedFile.path);
        savedFilePath = savedFile.path;
      }
    } catch (e) {
      debugPrint('Warning: Could not copy file to app documents directory: $e');
      savedFilePath = sourceFilePath;
    }

    final doc = AITutorDocument(
      id: id,
      title: title.trim(),
      pdfFileName: originalFileName,
      pdfPath: savedFilePath,
      createdAt: now,
      tasks: [],
    );

    final box = getBox();
    await box.add(doc);
    return doc;
  }

  /// Deletes a document and its local file if applicable
  static Future<void> deleteDocument(AITutorDocument doc) async {
    try {
      if (doc.pdfPath.isNotEmpty) {
        final file = File(doc.pdfPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Could not delete PDF file on disk: $e');
    }
    await doc.delete();
  }

  /// Adds a task to a document
  static Future<AITutorTask> addTask(
    AITutorDocument doc, {
    required String title,
    String description = '',
    String type = kTaskTypeSummarize,
    String status = kTaskStatusCompleted,
    String generatedContent = '',
    String questionsJson = '[]',
    String? errorMessage,
  }) async {
    final task = AITutorTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: doc.id,
      title: title.trim(),
      description: description.trim(),
      type: type,
      status: status,
      generatedContent: generatedContent,
      questionsJson: questionsJson,
      createdAt: DateTime.now(),
      errorMessage: errorMessage,
    );

    doc.tasks.add(task);
    await doc.save();
    return task;
  }

  /// Updates an existing task on a document
  static Future<void> updateTask(
    AITutorDocument doc,
    AITutorTask updatedTask,
  ) async {
    final index = doc.tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      updatedTask.updatedAt = DateTime.now();
      doc.tasks[index] = updatedTask;
      await doc.save();
    }
  }

  /// Records a new attempt for a task
  static Future<void> recordAttempt(
    AITutorDocument doc,
    String taskId,
    AITutorAttempt attempt,
  ) async {
    final index = doc.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = doc.tasks[index];
      task.addAttempt(attempt);
      await doc.save();
    }
  }

  /// Deletes a task from a document
  static Future<void> deleteTask(AITutorDocument doc, String taskId) async {
    doc.tasks.removeWhere((t) => t.id == taskId);
    await doc.save();
  }

  /// Toggles completion status of a task
  static Future<void> toggleTaskStatus(
    AITutorDocument doc,
    String taskId,
  ) async {
    final index = doc.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      doc.tasks[index].isCompleted = !doc.tasks[index].isCompleted;
      await doc.save();
    }
  }
}
