import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note_model.dart';
import 'note_storage_service.dart';

class NotePdfExportResult {
  final bool success;
  final String message;
  final String? filePath;

  const NotePdfExportResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class NotePdfService {
  /// Clean text so standard Helvetica font won't fail on Unicode characters
  static String _cleanText(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('•', '-')
        .replaceAll('·', '-')
        .replaceAll('—', '--')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('…', '...')
        .replaceAll('«', '"')
        .replaceAll('»', '"')
        .replaceAll('™', '(TM)')
        .replaceAll('©', '(C)')
        .replaceAll('®', '(R)')
        .replaceAll('°', ' deg')
        .replaceAll('±', '+/-')
        .replaceAll('×', 'x')
        .replaceAll('÷', '/')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        .replaceAll('≠', '!=')
        .replaceAll('≈', '~')
        .replaceAll('√', 'sqrt')
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[^\x00-\x7E\r\n\t]'), ' ');
  }

  /// Generates and exports the note as an executive PDF document
  static Future<NotePdfExportResult> exportNoteToPdf(Note note) async {
    try {
      final plainText = NoteStorageService.extractPlainText(note.content);
      final wordCount = NoteStorageService.countWords(note.content);

      if (kIsWeb) {
        // Web platform fallback - copy clean text to clipboard
        await Clipboard.setData(
          ClipboardData(text: '${note.title}\n\n$plainText'),
        );
        return const NotePdfExportResult(
          success: true,
          message: 'Document text copied to clipboard (Web mode).',
        );
      }

      final pdf = pw.Document();
      final cleanTitle = _cleanText(
        note.title.trim().isEmpty ? 'Untitled Document' : note.title,
      );
      final formattedDate = DateFormat(
        'MMMM d, y • h:mm a',
      ).format(note.updatedAt);

      // Parse rich content into PDF widgets
      final contentWidgets = _parseContentToPdfWidgets(note.content);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          header: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              margin: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.green800, width: 1.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AKUM CONNECT',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Document Studio • Academic Word Processor',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        formattedDate,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        '$wordCount words',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 14),
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AKUM Connect Document System',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (context) {
            return [
              // Document Title Presentation Box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                margin: const pw.EdgeInsets.only(bottom: 18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.green200, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      cleanTitle,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Last Modified: $formattedDate  |  Document Length: $wordCount words',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ...contentWidgets,
            ];
          },
        ),
      );

      // Save file
      final directory = await _getExportDirectory();
      String safeName = cleanTitle
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      if (safeName.isEmpty) safeName = 'AKUM_Document';
      final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Open the exported PDF
      try {
        await OpenFilex.open(file.path);
      } catch (_) {}

      return NotePdfExportResult(
        success: true,
        message: 'Document exported successfully to: ${file.path}',
        filePath: file.path,
      );
    } catch (e) {
      return NotePdfExportResult(
        success: false,
        message: 'Failed to export document: $e',
      );
    }
  }

  static Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          return publicDownloadDir;
        }
      } catch (_) {}

      try {
        final dlDir = await getDownloadsDirectory();
        if (dlDir != null && await dlDir.exists()) {
          return dlDir;
        }
      } catch (_) {}

      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final downloadDir = Directory('${extDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      try {
        final dlDir = await getDownloadsDirectory();
        if (dlDir != null && await dlDir.exists()) {
          return dlDir;
        }
      } catch (_) {}
    }
    return await getApplicationDocumentsDirectory();
  }

  static List<pw.Widget> _parseContentToPdfWidgets(String rawContent) {
    final widgets = <pw.Widget>[];

    // Check if rawContent is Quill Delta JSON
    final trimmed = rawContent.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
        // Parse Quill Delta ops
        final paragraphSpans = <pw.InlineSpan>[];
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              final attributes = op['attributes'] as Map<String, dynamic>?;
              final isBold = attributes?['bold'] == true;
              final isItalic = attributes?['italic'] == true;
              final isUnderline = attributes?['underline'] == true;
              final header = attributes?['header'];

              // If newline with header or block format
              if (insert.contains('\n')) {
                final parts = insert.split('\n');
                for (int i = 0; i < parts.length; i++) {
                  if (parts[i].isNotEmpty) {
                    paragraphSpans.add(
                      pw.TextSpan(
                        text: _cleanText(parts[i]),
                        style: pw.TextStyle(
                          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                          fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                          decoration: isUnderline ? pw.TextDecoration.underline : null,
                          fontSize: 10,
                          color: PdfColors.grey900,
                        ),
                      ),
                    );
                  }
                  if (i < parts.length - 1) {
                    // Flush current paragraph
                    if (paragraphSpans.isNotEmpty) {
                      if (header != null) {
                        final hSize = header == 1 ? 16.0 : (header == 2 ? 13.0 : 11.5);
                        widgets.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: List.from(paragraphSpans),
                                style: pw.TextStyle(
                                  fontSize: hSize,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green900,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        widgets.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: List.from(paragraphSpans),
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  height: 1.45,
                                  color: PdfColors.grey900,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      paragraphSpans.clear();
                    }
                  }
                }
              } else {
                paragraphSpans.add(
                  pw.TextSpan(
                    text: _cleanText(insert),
                    style: pw.TextStyle(
                      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                      decoration: isUnderline ? pw.TextDecoration.underline : null,
                      fontSize: 10,
                      color: PdfColors.grey900,
                    ),
                  ),
                );
              }
            }
          }
        }

        // Flush remaining spans
        if (paragraphSpans.isNotEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(children: paragraphSpans),
              ),
            ),
          );
        }

        if (widgets.isNotEmpty) return widgets;
      }
    } catch (_) {}
  }

    // Fallback: standard plain text lines
    final lines = rawContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text(
            _cleanText(trimmed),
            style: const pw.TextStyle(
              fontSize: 10,
              height: 1.4,
              color: PdfColors.grey900,
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
