import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/local_school_qa_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final AiService _aiService = AiService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late Box<String> _chatBox;

  static const String _messagesKey = 'history_v1';
  static const String _cachePrefix = 'cached_response_';

  // Sample prompt chips for student guidance and 0-quota answers
  final List<Map<String, String>> _suggestedPrompts = [
    {
      'title': 'Degree Classification',
      'subtitle': 'CGPA ranges & honors',
      'query': 'What is the degree classification and CGPA range at AKUM?',
      'icon': 'school',
    },
    {
      'title': 'Calculate CGPA',
      'subtitle': 'Step-by-step formula',
      'query': 'How do I calculate my CGPA?',
      'icon': 'calculate',
    },
    {
      'title': 'Faculties & Depts',
      'subtitle': 'All academic programmes',
      'query': 'What faculties and departments are in Abdulkadir Kure University?',
      'icon': 'account_balance',
    },
    {
      'title': 'Exam Guidelines',
      'subtitle': 'Hall rules & conduct',
      'query': 'What are the examination rules and misconduct penalties?',
      'icon': 'rule',
    },
    {
      'title': 'About the VC',
      'subtitle': 'Leadership & management',
      'query': 'Who is the Vice Chancellor of Abdulkadir Kure University?',
      'icon': 'person',
    },
    {
      'title': 'About this App',
      'subtitle': 'Features & developer',
      'query': 'Who developed AKUM Connect?',
      'icon': 'smartphone',
    },
  ];

  @override
  void initState() {
    super.initState();
    _chatBox = Hive.box<String>('ai_chat_box');
    _loadChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _loadChatHistory() {
    final rawHistory = _chatBox.get(_messagesKey);
    if (rawHistory != null && rawHistory.isNotEmpty) {
      setState(() {
        _messages = ChatMessage.decodeList(rawHistory);
      });
      _scrollToBottom(immediate: true);
    }
  }

  Future<void> _saveChatHistory() async {
    final jsonStr = ChatMessage.encodeList(_messages);
    await _chatBox.put(_messagesKey, jsonStr);
  }

  Future<void> _clearConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will remove all messages from this session. Quick prompts will be shown again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
      });
      await _chatBox.clear(); // Clears message history AND wrong cached answers
    }
  }

  String _normalizeForCache(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  Future<void> _sendMessage({String? predefinedText}) async {
    final text = (predefinedText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      message: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    if (predefinedText == null) {
      _controller.clear();
    }
    _scrollToBottom();
    await _saveChatHistory();

    // ONLY predefined suggested prompt clicks are routed offline to save quota.
    // All normal user-typed questions go straight to the real AI!
    final isSuggestedQuestion = predefinedText != null;

    if (isSuggestedQuestion) {
      // 1. Check if suggested prompt was answered before in cache
      final cacheKey = '$_cachePrefix${_normalizeForCache(text)}';
      final cachedAnswer = _chatBox.get(cacheKey);

      if (cachedAnswer != null && cachedAnswer.isNotEmpty) {
        debugPrint('⚡ QuotaShield: Suggested question served from local cache');
        await Future.delayed(const Duration(milliseconds: 250));

        final aiMsg = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'model',
          message: cachedAnswer,
          timestamp: DateTime.now(),
          isFromCache: true,
          provider: 'cache',
        );

        if (mounted) {
          setState(() {
            _messages.add(aiMsg);
            _isLoading = false;
          });
          _scrollToBottom();
          await _saveChatHistory();
        }
        return;
      }

      // 2. Answer suggested questions using local school knowledge
      try {
        final localAnswer = await LocalSchoolQaService().tryAnswer(text);
        if (localAnswer != null && localAnswer.isNotEmpty) {
          debugPrint('🏫 QuotaShield: Suggested question answered offline (0 quota)');
          await Future.delayed(const Duration(milliseconds: 300));

          final aiMsg = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            role: 'model',
            message: localAnswer,
            timestamp: DateTime.now(),
            isFromCache: true,
            provider: 'local',
          );

          await _chatBox.put(cacheKey, localAnswer);

          if (mounted) {
            setState(() {
              _messages.add(aiMsg);
              _isLoading = false;
            });
            _scrollToBottom();
            await _saveChatHistory();
          }
          return;
        }
      } catch (e) {
        debugPrint('Offline answer error for suggested prompt: $e');
      }
    }

    // -------------------------------------------------------------
    // ALL USER TYPED QUESTIONS GO DIRECTLY TO THE REAL AI STREAM!
    // (Gemini -> Groq -> SambaNova)
    // -------------------------------------------------------------
    final aiPlaceholder = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'model',
      message: '',
      timestamp: DateTime.now(),
      isFromCache: false,
      provider: 'ai',
    );

    setState(() {
      _messages.add(aiPlaceholder);
    });

    String fullResponse = '';
    try {
      final responseStream = _aiService.sendMessageStream(text);
      await for (final chunk in responseStream) {
        if (!mounted) return;
        fullResponse += chunk;
        setState(() {
          _messages.last.message = fullResponse;
        });
        _scrollToBottom();
      }

      // Cache successful response to protect quota on repeat questions
      if (fullResponse.trim().isNotEmpty) {
        final cacheKey = '$_cachePrefix${_normalizeForCache(text)}';
        await _chatBox.put(cacheKey, fullResponse);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (fullResponse.isEmpty) {
          _messages.last.message =
              "⚠️ Unable to connect to the assistant right now.\n\nPlease check your internet connection or ask school-specific questions (faculties, CGPA, exams) which work offline!";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
        await _saveChatHistory();
      }
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AKUM AI Assistant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Quota-Optimized • Ready',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear conversation',
            onPressed: _messages.isEmpty ? null : _clearConversation,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Quota Saver Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              border: Border(
                bottom: BorderSide(color: Colors.green.shade200, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.green.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI-Powered Assistant • Suggested questions are instant & offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Chat Area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // Modern Empty State with Quick Prompt Cards
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.school, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to AKUM AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your intelligent campus companion. Ask about courses, examinations, CGPA rules, or campus guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.bolt, size: 16, color: Color(0xFF1B5E20)),
                SizedBox(width: 6),
                Text(
                  'Suggested Questions (Instant & Offline)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((p) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 0,
                child: InkWell(
                  onTap: () => _sendMessage(predefinedText: p['query']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p['subtitle']!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Modern Message Bubble with Avatar, Copy Action, and Quota Badges
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 16, color: Colors.white),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1B5E20) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          msg.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.message.isEmpty && _isLoading)
                              _buildTypingDots()
                            else
                              MarkdownBody(
                                data: msg.message,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Color(0xFF1E293B),
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey.shade100,
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),

                            // Footer bar inside AI response: copy & quota badges
                            if (msg.message.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (msg.isFromCache) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt,
                                            size: 11,
                                            color: Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '0 Quota Used',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  InkWell(
                                    onTap: () => _copyToClipboard(msg.message),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.copy,
                                            size: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Copy',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // Smooth typing dots animation while waiting for response
  Widget _buildTypingDots() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1B5E20),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 38),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AKUM AI is typing...',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Input Bar with Multiline Support & Clean Send Button
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _inputFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything about AKUM...',
                    hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF1B5E20),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _isLoading ? null : () => _sendMessage(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
