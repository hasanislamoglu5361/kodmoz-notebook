class Notebook {
  Notebook({
    required this.id,
    required this.name,
    this.description,
    required this.archived,
    required this.created,
    required this.updated,
    this.sourceCount = 0,
    this.noteCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final bool archived;
  final String created;
  final String updated;
  final int sourceCount;
  final int noteCount;

  factory Notebook.fromJson(Map<String, dynamic> j) => Notebook(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Untitled').toString(),
        description: j['description']?.toString(),
        archived: j['archived'] == true,
        created: (j['created'] ?? '').toString(),
        updated: (j['updated'] ?? '').toString(),
        sourceCount: (j['source_count'] is num)
            ? (j['source_count'] as num).toInt()
            : 0,
        noteCount: (j['note_count'] is num)
            ? (j['note_count'] as num).toInt()
            : 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'archived': archived,
        'created': created,
        'updated': updated,
        'source_count': sourceCount,
        'note_count': noteCount,
      };

  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }
}
