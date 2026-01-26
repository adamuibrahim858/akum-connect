import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';

class NoteStorageService {
  static const String boxName = 'notes';

  static Box<Note> getBox() {
    return Hive.box<Note>(boxName);
  }

  // Add a new note
  static Future<void> addNote(String title, String content) async {
    final box = getBox();
    final now = DateTime.now();
    final note = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await box.add(note);
  }

  // Update existing note
  static Future<void> updateNote(
    Note note,
    String title,
    String content,
  ) async {
    note.title = title;
    note.content = content;
    note.updatedAt = DateTime.now();
    await note.save();
  }

  // Delete note
  static Future<void> deleteNote(Note note) async {
    await note.delete();
  }
}
