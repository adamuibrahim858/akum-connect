import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SummaryPdfService {
  /// Generates a professional branded PDF from the summary markdown content and saves it
  static Future<File> generateAndSaveSummaryPdf({
    required String summaryTitle,
    required String originalDocumentTitle,
    required String summaryMarkdown,
  }) async {
    final pdf = pw.Document();

    final formattedDate = DateFormat(
      'MMMM d, y • h:mm a',
    ).format(DateTime.now());

    // Clean filename
    final safeFileName =
        '${summaryTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf';

    // Parse markdown lines into PDF widgets
    final contentWidgets = _parseMarkdownToPdfWidgets(summaryMarkdown);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.green700, width: 1.5),
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
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      'AI Tutor • Academic Study Note',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Abdulkadir Kure University',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
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
            margin: const pw.EdgeInsets.only(top: 12),
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
                  'Original Source: $originalDocumentTitle',
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
            // Title Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              margin: const pw.EdgeInsets.only(bottom: 18),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green200, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    summaryTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Source Document: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text(
                        originalDocumentTitle,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Body Content
            ...contentWidgets,
          ];
        },
      ),
    );

    // Save to persistent storage
    final outputDir = await _getStorageDirectory();
    final file = File('${outputDir.path}/$safeFileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<Directory> _getStorageDirectory() async {
    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final downloadDir = Directory('${extDir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      }
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }

  static List<pw.Widget> _parseMarkdownToPdfWidgets(String markdown) {
    final List<pw.Widget> widgets = [];
    final lines = markdown.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('# ')) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(
          pw.Text(
            line.substring(2).trim(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
      } else if (line.startsWith('## ')) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(
          pw.Text(
            line.substring(3).trim(),
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
      } else if (line.startsWith('### ')) {
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(
          pw.Text(
            line.substring(4).trim(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 3));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 4, right: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green700,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    bulletText,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey900,
                      lineSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              line,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey900,
                lineSpacing: 1.4,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
