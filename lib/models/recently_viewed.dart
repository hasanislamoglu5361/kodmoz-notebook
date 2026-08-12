class RecentlyViewedItem {
  RecentlyViewedItem({
    required this.type,
    required this.id,
    required this.title,
    required this.lastViewedAt,
  });

  final String type; // 'notebook' | 'source'
  final String id;
  final String title;
  final String lastViewedAt;

  factory RecentlyViewedItem.fromJson(Map<String, dynamic> j) =>
      RecentlyViewedItem(
        type: (j['type'] ?? 'notebook').toString(),
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Untitled').toString(),
        lastViewedAt: (j['last_viewed_at'] ?? '').toString(),
      );

  bool get isNotebook => type == 'notebook';
  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }
}
