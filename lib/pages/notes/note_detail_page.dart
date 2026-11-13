import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/note_pdf_service.dart';
import '../../services/note_storage_service.dart';
import 'add_edit_note_page.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Note _currentNote;
  late QuillController _quillController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _initQuillController();
  }

  void _initQuillController() {
    final doc = NoteStorageService.parseDocument(_currentNote.content);
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _deleteNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to permanently delete "${_currentNote.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await NoteStorageService.deleteNote(_currentNote);
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

  Future<void> _exportPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating document PDF...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await NotePdfService.exportNoteToPdf(_currentNote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
  }

  void _copyDocumentText() {
    final plainText = NoteStorageService.extractPlainText(_currentNote.content);
    final fullDoc = '${_currentNote.title}\n\n$plainText';
    Clipboard.setData(ClipboardData(text: fullDoc));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Document text copied to clipboard'),
          ],
        ),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _duplicateDocument() async {
    final copy = await NoteStorageService.duplicateNote(_currentNote);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created duplicate: "${copy.title}"'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width > 700;
    final wordCount = NoteStorageService.countWords(_currentNote.content);
    final readingTime = NoteStorageService.estimateReadingTimeMinutes(_currentNote.content);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Workspace light canvas
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 2,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentNote.title.isEmpty ? 'Untitled Document' : _currentNote.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Document Viewer • Last modified ${DateFormat('MMM d, h:mm a').format(_currentNote.updatedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export as PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Copy Document Text',
            onPressed: _copyDocumentText,
            icon: const Icon(Icons.content_copy_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEdit();
              } else if (value == 'duplicate') {
                _duplicateDocument();
              } else if (value == 'delete') {
                _deleteNote(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: Color(0xFF1B5E20)),
                    SizedBox(width: 10),
                    Text('Edit in Studio'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_all, size: 20, color: Color(0xFF334155)),
                    SizedBox(width: 10),
                    Text('Make a Copy'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Document', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktopOrTablet ? 32 : 12,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _buildDocumentPaper(wordCount, readingTime),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEdit,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_note),
        label: const Text('Edit Document'),
      ),
    );
  }

  void _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditNotePage(note: _currentNote),
      ),
    );
    // Refresh state after returning from edit
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _initQuillController();
    setState(() {});
  }

  Widget _buildDocumentPaper(int wordCount, int readingTime) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Authentic Top Ruler Margin
          _buildRulerHeader(),

          Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Formal Document Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AKUM CONNECT • DOCUMENT STUDIO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                              letterSpacing: 0.6,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Text(
                              'Verified Academic Document',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentNote.title.isEmpty ? 'Untitled Document' : _currentNote.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(
                            'Created ${DateFormat('MMMM d, y').format(_currentNote.createdAt)} • Updated ${DateFormat('h:mm a').format(_currentNote.updatedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$wordCount words • $readingTime min read',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                ),

                // Rendered Rich Document Content (WYSIWYG Viewer)
                _quillController.document.toPlainText().trim().isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: const [
                            Icon(Icons.notes, size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'This document has no content.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 200),
                        child: QuillEditor.basic(
                          controller: _quillController,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          config: const QuillEditorConfig(
                            scrollable: false,
                            autoFocus: false,
                            expands: false,
                            showCursor: false,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                const SizedBox(height: 56),

                // Printed Document Page Footer
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AKUM Connect Document System',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Page 1 of 1 • Doc ID: #${_currentNote.id.substring(
                          _currentNote.id.length > 6 ? _currentNote.id.length - 6 : 0,
                        )}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulerHeader() {
    return Container(
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF2E7D32)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                return Row(
                  children: [
                    Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 6, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 4, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 6, color: const Color(0xFFCBD5E1)),
                  ],
                );
              }),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF2E7D32)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
