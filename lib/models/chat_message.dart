import 'dart:convert';

/// Represents a single chat message in the AI chatbot conversation.
/// Stored as JSON strings in Hive to avoid needing a TypeAdapter.
class ChatMessage {
  final String id;

  /// 'user' | 'model' | 'error'
  final String role;

  String message; // mutable so streaming can append chunks

  final DateTime timestamp;

  /// True when the answer came from local cache (no API quota used)
  final bool isFromCache;

  /// Which provider answered: 'local', 'gemini', 'groq', 'sambanova'
  final String provider;

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    required this.timestamp,
    this.isFromCache = false,
    this.provider = 'gemini',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isFromCache': isFromCache,
    'provider': provider,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isFromCache: (json['isFromCache'] as bool?) ?? false,
    provider: (json['provider'] as String?) ?? 'gemini',
  );

  /// Encode a list of messages to a JSON string for Hive storage
  static String encodeList(List<ChatMessage> messages) =>
      jsonEncode(messages.map((m) => m.toJson()).toList());

  /// Decode a JSON string from Hive back to a list of messages
  static List<ChatMessage> decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

