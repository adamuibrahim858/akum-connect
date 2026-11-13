import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';

class NoteStorageService {
  static const String boxName = 'notes';

  static Box<Note> getBox() {
    return Hive.box<Note>(boxName);
  }

  /// Sanitize raw stored string to remove bad control characters that break JSON
  static String _sanitizeJson(String raw) {
    // Replace raw control characters (0x00–0x1F) EXCEPT standard ones
    // that JSON allows escaped: \t (0x09), \n (0x0A), \r (0x0D)
    // We replace them with a space so the JSON can at least be parsed.
    return raw.replaceAllMapped(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      (_) => ' ',
    );
  }

  /// Parse raw stored content into a Quill Document
  static Document parseDocument(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return Document();
    }

    final trimmed = _sanitizeJson(rawContent.trim());

    // Only attempt JSON Delta decoding if it looks like a JSON array
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          return Document.fromJson(List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e as Map)),
          ));
        }
      } on FormatException catch (_) {
        // JSON was malformed even after sanitization; fall through to plain text
      } catch (_) {
        // Document.fromJson failed; fall through to plain text
      }
    }

    // Fallback: treat as plain text
    final doc = Document();
    try {
      // Strip any remaining control chars from plain text too
      final safe = rawContent.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
      if (safe.isNotEmpty) doc.insert(0, safe);
    } catch (_) {}
    return doc;
  }

  /// Extract clean plain text for searching, list previews, and word counts
  static String extractPlainText(String rawContent) {
    if (rawContent.trim().isEmpty) return '';

    final trimmed = _sanitizeJson(rawContent.trim());
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          final doc = Document.fromJson(List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e as Map)),
          ));
          return doc.toPlainText().trim();
        }
      } catch (_) {}
    }

    return rawContent.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '').trim();
  }

  // Add a new note
  static Future<Note> addNote(String title, String content) async {
    final box = getBox();
    final now = DateTime.now();
    final note = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Untitled Document' : title.trim(),
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await box.add(note);
    return note;
  }

  // Update existing note
  static Future<void> updateNote(
    Note note,
    String title,
    String content,
  ) async {
    note.title = title.trim().isEmpty ? 'Untitled Document' : title.trim();
    note.content = content;
    note.updatedAt = DateTime.now();
    await note.save();
  }

  // Duplicate note
  static Future<Note> duplicateNote(Note original) async {
    final now = DateTime.now();
    final copy = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      content: original.content,
      createdAt: now,
      updatedAt: now,
    );
    await getBox().add(copy);
    return copy;
  }

  // Delete note
  static Future<void> deleteNote(Note note) async {
    await note.delete();
  }

  // Word count utility based on clean plain text
  static int countWords(String text) {
    final plainText = extractPlainText(text);
    if (plainText.isEmpty) return 0;
    return RegExp(r'\S+').allMatches(plainText).length;
  }

  // Character count utility based on clean plain text
  static int countCharacters(String text) {
    final plainText = extractPlainText(text);
    return plainText.length;
  }

  // Reading time estimate (average 200 words per minute)
  static int estimateReadingTimeMinutes(String text) {
    final words = countWords(text);
    if (words == 0) return 0;
    final mins = (words / 200).ceil();
    return mins < 1 ? 1 : mins;
  }
}
