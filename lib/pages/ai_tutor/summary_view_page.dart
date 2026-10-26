import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ai_tutor_model.dart';
import '../../services/summary_pdf_service.dart';

class SummaryViewPage extends StatefulWidget {
  final AITutorDocument document;
  final AITutorTask task;

  const SummaryViewPage({
    super.key,
    required this.document,
    required this.task,
  });

  @override
  State<SummaryViewPage> createState() => _SummaryViewPageState();
}

class _SummaryViewPageState extends State<SummaryViewPage> {
  bool _isDownloadingPdf = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  String get _displayedContent {
    final content = widget.task.generatedContent;
    if (_searchQuery.isEmpty) return content;
    final lines = content.split('\n');
    final matching = lines
        .where((l) => l.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    if (matching.isEmpty) {
      return '*(No matching content found for "$_searchQuery")*';
    }
    return '### Search Results for "$_searchQuery":\n\n${matching.join('\n\n')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDownloadPdf() async {
    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final file = await SummaryPdfService.generateAndSaveSummaryPdf(
        summaryTitle: widget.task.title,
        originalDocumentTitle: widget.document.title,
        summaryMarkdown: widget.task.generatedContent,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved as PDF: ${file.path.split('/').last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.yellow,
            onPressed: () async {
              try {
                final uri = Uri.file(file.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              } catch (_) {}
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  void _handleCopyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.task.generatedContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search in summary...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              )
            : const Text(
                'Academic Summary',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Summary',
            onPressed: _handleCopyToClipboard,
          ),
          IconButton(
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF',
            onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Source: ${widget.document.title}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 90),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: MarkdownBody(
                    data: _displayedContent.isNotEmpty
                        ? _displayedContent
                        : '*No summary content available.*',
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                        height: 1.4,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        height: 1.4,
                      ),
                      h3: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      p: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      listBullet: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: Colors.green.shade600,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              _isDownloadingPdf
                  ? 'Generating PDF...'
                  : 'Download Summary as PDF',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
