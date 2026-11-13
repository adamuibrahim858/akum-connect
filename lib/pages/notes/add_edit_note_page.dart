import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/note_pdf_service.dart';
import '../../services/note_storage_service.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  late ScrollController _editorScrollController;

  bool _hasUnsavedChanges = false;
  int _wordCount = 0;
  int _charCount = 0;
  int _readingTime = 0;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.note?.title ?? '';
    final initialContent = widget.note?.content ?? '';

    _titleController = TextEditingController(text: initialTitle);
    _titleController.addListener(_onTitleChanged);

    // Load Quill Document from stored content
    final doc = NoteStorageService.parseDocument(initialContent);
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();

    _updateStats();
    _quillController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _onContentChanged() {
    _updateStats();
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _updateStats() {
    final plainText = _quillController.document.toPlainText().trim();
    final words = plainText.isEmpty ? 0 : RegExp(r'\S+').allMatches(plainText).length;
    final chars = plainText.length;
    final mins = words == 0 ? 0 : (words / 200).ceil();

    setState(() {
      _wordCount = words;
      _charCount = chars;
      _readingTime = mins < 1 && words > 0 ? 1 : mins;
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save an empty document.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final finalTitle = title.isEmpty ? 'Untitled Document' : title;
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    if (widget.note == null) {
      await NoteStorageService.addNote(finalTitle, contentJson);
    } else {
      await NoteStorageService.updateNote(widget.note!, finalTitle, contentJson);
    }

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Document saved successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _exportPdf() async {
    final title = _titleController.text.trim().isEmpty ? 'Untitled Document' : _titleController.text.trim();
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    final tempNote = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: contentJson,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

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

    final result = await NotePdfService.exportNoteToPdf(tempNote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes in this document. Do you want to discard them or save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEEP EDITING'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx, false);
              await _saveNote();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE & EXIT'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width > 700;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Workspace light canvas
        appBar: _buildWordProcessorAppBar(),
        body: Column(
          children: [
            // True WYSIWYG Formatting Ribbon Toolbar (Like Google Docs / Word)
            _buildWysiwygToolbar(),

            // Document Canvas (Paper Sheet)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktopOrTablet ? 32 : 12,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: _buildPaperSheet(),
                  ),
                ),
              ),
            ),

            // Word Processor Status Bar (Footer)
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildWordProcessorAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Documents',
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.pop(context);
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              const Text(
                'Document Studio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges
                      ? Colors.amber.shade800
                      : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasUnsavedChanges ? Icons.edit : Icons.check_circle,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hasUnsavedChanges ? 'Editing' : 'Saved',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            widget.note == null
                ? 'Untitled Document'
                : 'Last updated ${DateFormat('MMM d, h:mm a').format(widget.note!.updatedAt)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        // Export PDF
        IconButton(
          tooltip: 'Export Document to PDF',
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: _exportPdf,
        ),

        // Save Button
        Padding(
          padding: const EdgeInsets.only(right: 12.0, left: 4.0),
          child: ElevatedButton.icon(
            onPressed: _saveNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.save, size: 18),
            label: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // True WYSIWYG Ribbon Toolbar (Google Docs / Microsoft Word Ribbon)
  Widget _buildWysiwygToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: const QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showInlineCode: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showHeaderStyle: true,
          showListBullets: true,
          showListNumbers: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: false,
          showUndo: true,
          showRedo: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: true,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showFontFamily: false,
          showFontSize: true,
        ),
      ),
    );
  }

  // The Realistic "Paper Sheet"
  Widget _buildPaperSheet() {
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
          // Word Processor Top Margin Ruler
          _buildRulerHeader(),

          // Document Header & Body
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Document Title (e.g. CSC 301 Lecture Notes)',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 8),

                // Document Metadata Subheader
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      widget.note == null
                          ? 'Created ${DateFormat('MMMM d, y').format(DateTime.now())}'
                          : 'Created ${DateFormat('MMM d, y').format(widget.note!.createdAt)} • Updated ${DateFormat('h:mm a').format(widget.note!.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        '$_wordCount words • $_readingTime min read',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
                ),

                // The Live WYSIWYG Quill Editor (No symbols or asterisks!)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 350),
                  child: Builder(
                    builder: (context) {
                      try {
                        return QuillEditor.basic(
                          controller: _quillController,
                          focusNode: _editorFocusNode,
                          scrollController: _editorScrollController,
                          config: const QuillEditorConfig(
                            placeholder: 'Start typing your document here...',
                            scrollable: false,
                            autoFocus: false,
                            expands: false,
                            padding: EdgeInsets.zero,
                          ),
                        );
                      } catch (e) {
                        // If the stored document is corrupt, reset to empty
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _quillController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Note content could not be loaded — starting fresh.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        });
                        return const SizedBox(
                          height: 350,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // Page Footer (Like in printed documents)
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
                        'AKUM Connect Document Studio',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Page 1 of 1 • ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
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

  // Word processor authentic margin ruler
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

  // Word Processor Status Bar (Docked at screen bottom)
  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Text(
                'Page 1 of 1',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 12),
              Text(
                '$_wordCount words',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 12),
              Text(
                '$_charCount characters',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Reading time: ~$_readingTime min',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    _hasUnsavedChanges ? Icons.fiber_manual_record : Icons.check_circle,
                    size: 11,
                    color: _hasUnsavedChanges ? Colors.orange : const Color(0xFF1B5E20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _hasUnsavedChanges ? 'Unsaved' : 'Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _hasUnsavedChanges ? Colors.orange.shade800 : const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
