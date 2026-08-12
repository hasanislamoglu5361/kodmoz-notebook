class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    this.notebookId,
    required this.created,
    required this.updated,
    this.messageCount = 0,
    this.modelOverride,
  });

  final String id;
  final String title;
  final String? notebookId;
  final String created;
  final String updated;
  final int messageCount;
  final String? modelOverride;

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Untitled session').toString(),
        notebookId: j['notebook_id']?.toString(),
        created: (j['created'] ?? '').toString(),
        updated: (j['updated'] ?? '').toString(),
        messageCount: (j['message_count'] is num)
            ? (j['message_count'] as num).toInt()
            : 0,
        modelOverride: j['model_override']?.toString(),
      );

  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }
}
