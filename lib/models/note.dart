class Note {
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.noteType,
    required this.created,
    required this.updated,
  });

  final String id;
  final String title;
  final String content;
  final String noteType; // 'human' | 'ai'
  final String created;
  final String updated;

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Untitled').toString(),
        content: (j['content'] ?? '').toString(),
        noteType: (j['note_type'] ?? 'human').toString(),
        created: (j['created'] ?? '').toString(),
        updated: (j['updated'] ?? '').toString(),
      );

  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }

  bool get isAi => noteType == 'ai';
}
