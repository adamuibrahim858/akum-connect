import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:akum_connet/services/summary_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateAndSaveSummaryPdf test', () async {
    try {
      final file = await SummaryPdfService.generateAndSaveSummaryPdf(
        summaryTitle: 'CS101 Summary: Introduction to OS',
        originalDocumentTitle: 'OS_Chapter1.pdf',
        summaryMarkdown: '''
# Operating System Overview
An Operating System (OS) is system software that manages computer hardware, software resources, and provides common services for computer programs.

## Key Functions:
- Process Management • Handling multitasking
- Memory Management: Allocation & deallocation
- File System Management: Directories and permissions
- "Smart quotes" and 'apostrophes' test — em-dash

### Conclusion
OS acts as an intermediary between users and computer hardware.
''',
      );
      print('Generated file: ${file.path}, exists: ${file.existsSync()}');
    } catch (e, stack) {
      print('Error generating PDF: $e');
      print(stack);
      rethrow;
    }
  });
}
