class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
  });

  final String role; // 'user' | 'assistant' | 'system'
  final String content;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: (j['role'] ?? 'user').toString(),
        content: (j['content'] ?? '').toString(),
      );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
