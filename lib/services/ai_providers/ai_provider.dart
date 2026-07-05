abstract class AiProvider {
  /// Unique identifier for the provider (e.g., 'gemini', 'openai').
  String get id;

  /// Initializes the provider with a system prompt (optional).
  void init(String systemPrompt);

  /// Sends a message to the AI provider and returns the response.
  /// Throws exceptions on failure (Quota, Auth, Network).
  Future<String> sendMessage(String message);
}
