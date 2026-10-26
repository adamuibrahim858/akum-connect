import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedPdfData {
  final String text;
  final int pageCount;
  final Uint8List rawBytes;
  final bool isScannedOrEmptyText;

  const ExtractedPdfData({
    required this.text,
    required this.pageCount,
    required this.rawBytes,
    required this.isScannedOrEmptyText,
  });
}

class PdfExtractorService {
  /// Maximum text length in characters to send in a single AI prompt
  static const int maxOptimalCharLength = 28000;

  /// Extracts text and metadata from the given PDF file path
  static Future<ExtractedPdfData> extractFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('PDF document not found on storage device: $filePath');
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('The uploaded PDF file is empty (0 bytes).');
    }

    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;

      if (pageCount == 0) {
        throw Exception('The PDF file contains no pages.');
      }

      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String extractedText = '';

      try {
        extractedText = extractor.extractText();
      } catch (e) {
        debugPrint('Warning: Text extraction encountered an issue: $e');
        extractedText = '';
      }

      // Clean & normalize text
      extractedText = _cleanText(extractedText);

      final bool isScannedOrEmpty = extractedText.trim().length < 50;

      // If document is very long, chunk or condense into optimal size
      if (extractedText.length > maxOptimalCharLength) {
        extractedText = _chunkAndCondenseText(extractedText);
      }

      return ExtractedPdfData(
        text: extractedText,
        pageCount: pageCount,
        rawBytes: bytes,
        isScannedOrEmptyText: isScannedOrEmpty,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to process PDF: $e');
    } finally {
      document?.dispose();
    }
  }

  /// Cleans raw extracted text, removes extraneous control characters and normalizes whitespaces
  static String _cleanText(String input) {
    if (input.isEmpty) return '';

    return input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(
          RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
          '',
        ) // remove non-printable
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // collapse multiple blank lines
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ') // collapse multi-spaces
        .trim();
  }

  /// Intelligently condenses very large text by taking representative sections
  /// (beginning, middle, and end) to avoid blowing token limits while retaining full academic scope.
  static String _chunkAndCondenseText(String fullText) {
    if (fullText.length <= maxOptimalCharLength) return fullText;

    final int sectionSize = (maxOptimalCharLength / 3).floor();
    final String beginning = fullText.substring(0, sectionSize);
    final int middleStart = ((fullText.length / 2) - (sectionSize / 2)).floor();
    final String middle = fullText.substring(
      middleStart,
      middleStart + sectionSize,
    );
    final String end = fullText.substring(fullText.length - sectionSize);

    return '$beginning\n\n[... Academic content omitted for length ...]\n\n$middle\n\n[... Academic content omitted for length ...]\n\n$end';
  }
}
