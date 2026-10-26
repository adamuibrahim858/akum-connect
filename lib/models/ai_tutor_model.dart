import 'dart:convert';
import 'package:hive/hive.dart';

const String kTaskTypeSummarize = 'summarize';
const String kTaskTypeEssay = 'essay';
const String kTaskTypeObjective = 'objective';

const String kTaskStatusGenerating = 'generating';
const String kTaskStatusCompleted = 'completed';
const String kTaskStatusFailed = 'failed';

class AITutorQuestion {
  final String id;
  final String taskId;
  final String question;
  final List<String> options;
  final dynamic correctAnswer; // int index (0-3) for MCQs, or String for essay
  final String expectedAnswer;
  final String explanation;
  final String topic;
  final int marks;
  dynamic studentAnswer;

  AITutorQuestion({
    required this.id,
    this.taskId = '',
    required this.question,
    this.options = const [],
    this.correctAnswer,
    this.expectedAnswer = '',
    this.explanation = '',
    this.topic = '',
    this.marks = 10,
    this.studentAnswer,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'expectedAnswer': expectedAnswer,
    'explanation': explanation,
    'topic': topic,
    'marks': marks,
    'studentAnswer': studentAnswer,
  };

  factory AITutorQuestion.fromJson(Map<String, dynamic> json) {
    return AITutorQuestion(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: json['correctAnswer'],
      expectedAnswer: json['expectedAnswer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      marks: (json['marks'] is num) ? (json['marks'] as num).toInt() : 10,
      studentAnswer: json['studentAnswer'],
    );
  }
}

class AITutorAttempt {
  final String id;
  final String taskId;
  final Map<String, dynamic> answers;
  final double score;
  final double maxScore;
  final double percentage;
  final String performance;
  final String feedback;
  final List<String> recommendations;
  final List<String> areasToRead;
  final List<Map<String, dynamic>> questionGradings;
  final DateTime submittedAt;

  AITutorAttempt({
    required this.id,
    required this.taskId,
    this.answers = const {},
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.performance,
    this.feedback = '',
    this.recommendations = const [],
    this.areasToRead = const [],
    this.questionGradings = const [],
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'answers': answers,
    'score': score,
    'maxScore': maxScore,
    'percentage': percentage,
    'performance': performance,
    'feedback': feedback,
    'recommendations': recommendations,
    'areasToRead': areasToRead,
    'questionGradings': questionGradings,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory AITutorAttempt.fromJson(Map<String, dynamic> json) {
    return AITutorAttempt(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      answers: (json['answers'] as Map?)?.cast<String, dynamic>() ?? {},
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      performance: json['performance']?.toString() ?? 'Completed',
      feedback: json['feedback']?.toString() ?? '',
      recommendations:
          (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      areasToRead:
          (json['areasToRead'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      questionGradings:
          (json['questionGradings'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          [],
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@HiveType(typeId: 5)
class AITutorTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String documentId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  String type; // 'summarize', 'essay', 'objective'

  @HiveField(7)
  String status; // 'generating', 'completed', 'failed'

  @HiveField(8)
  String generatedContent;

  @HiveField(9)
  String questionsJson;

  @HiveField(10)
  String attemptsJson;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  String? errorMessage;

  AITutorTask({
    required this.id,
    required this.documentId,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.isCompleted = false,
    this.type = kTaskTypeSummarize,
    this.status = kTaskStatusCompleted,
    this.generatedContent = '',
    this.questionsJson = '[]',
    this.attemptsJson = '[]',
    this.updatedAt,
    this.errorMessage,
  });

  List<AITutorQuestion> get questions {
    if (questionsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(questionsJson);
      if (decoded is List) {
        return decoded
            .map((e) => AITutorQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  set questions(List<AITutorQuestion> list) {
    questionsJson = jsonEncode(list.map((q) => q.toJson()).toList());
  }

  List<AITutorAttempt> get attempts {
    if (attemptsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(attemptsJson);
      if (decoded is List) {
        return decoded
            .map((e) => AITutorAttempt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  set attempts(List<AITutorAttempt> list) {
    attemptsJson = jsonEncode(list.map((a) => a.toJson()).toList());
  }

  AITutorAttempt? get latestAttempt {
    final list = attempts;
    if (list.isEmpty) return null;
    return list.last;
  }

  void addAttempt(AITutorAttempt attempt) {
    final current = attempts;
    current.add(attempt);
    attempts = current;
    isCompleted = true;
    updatedAt = DateTime.now();
  }
}

class AITutorTaskAdapter extends TypeAdapter<AITutorTask> {
  @override
  final int typeId = 5;

  @override
  AITutorTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AITutorTask(
      id: fields[0] as String,
      documentId: fields[1] as String,
      title: fields[2] as String,
      description: (fields[3] as String?) ?? '',
      createdAt: fields[4] as DateTime,
      isCompleted: (fields[5] as bool?) ?? false,
      type: (fields[6] as String?) ?? kTaskTypeSummarize,
      status: (fields[7] as String?) ?? kTaskStatusCompleted,
      generatedContent: (fields[8] as String?) ?? '',
      questionsJson: (fields[9] as String?) ?? '[]',
      attemptsJson: (fields[10] as String?) ?? '[]',
      updatedAt: fields[11] as DateTime?,
      errorMessage: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AITutorTask obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.generatedContent)
      ..writeByte(9)
      ..write(obj.questionsJson)
      ..writeByte(10)
      ..write(obj.attemptsJson)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITutorTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: 4)
class AITutorDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String pdfFileName;

  @HiveField(3)
  String pdfPath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  List<AITutorTask> tasks;

  AITutorDocument({
    required this.id,
    required this.title,
    required this.pdfFileName,
    required this.pdfPath,
    required this.createdAt,
    List<AITutorTask>? tasks,
  }) : tasks = tasks ?? [];
}

class AITutorDocumentAdapter extends TypeAdapter<AITutorDocument> {
  @override
  final int typeId = 4;

  @override
  AITutorDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawTasks = fields[5];
    final List<AITutorTask> parsedTasks = [];
    if (rawTasks is List) {
      for (final item in rawTasks) {
        if (item is AITutorTask) {
          parsedTasks.add(item);
        }
      }
    }

    return AITutorDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      pdfFileName: fields[2] as String,
      pdfPath: fields[3] as String,
      createdAt: fields[4] as DateTime,
      tasks: parsedTasks,
    );
  }

  @override
  void write(BinaryWriter writer, AITutorDocument obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.pdfFileName)
      ..writeByte(3)
      ..write(obj.pdfPath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.tasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITutorDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
