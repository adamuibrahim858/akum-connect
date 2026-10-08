import 'package:hive/hive.dart';

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

  AITutorTask({
    required this.id,
    required this.documentId,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.isCompleted = false,
  });
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
    );
  }

  @override
  void write(BinaryWriter writer, AITutorTask obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.isCompleted);
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
