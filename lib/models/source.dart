class Source {
  Source({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.url,
    this.filePath,
    this.notebookIds = const [],
    this.created = '',
    this.updated = '',
  });

  final String id;
  final String title;
  final String type; // 'link' | 'upload' | 'text'
  final String status; // 'ready' | 'processing' | 'failed' | etc.
  final String? url;
  final String? filePath;
  final List<String> notebookIds;
  final String created;
  final String updated;

  factory Source.fromJson(Map<String, dynamic> j) => Source(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Untitled source').toString(),
        type: (j['type'] ?? 'link').toString(),
        status: (j['status'] ?? 'unknown').toString(),
        url: j['url']?.toString(),
        filePath: j['file_path']?.toString(),
        notebookIds: (j['notebooks'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        created: (j['created'] ?? '').toString(),
        updated: (j['updated'] ?? '').toString(),
      );

  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }
}
