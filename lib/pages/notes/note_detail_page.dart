import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/note_storage_service.dart';
import 'add_edit_note_page.dart';

class NoteDetailPage extends StatelessWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  void _deleteNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await NoteStorageService.deleteNote(note);
              if (context.mounted) {
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context); // Close Page
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(note.title),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AddEditNotePage(note: note)),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _deleteNote(context),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, y • h:mm a').format(note.updatedAt),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              note.content,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
