String fmtRelative(String iso) {
  if (iso.isEmpty) return '';
  DateTime? dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final now = DateTime.now();
  final diff = now.difference(dt.toLocal());
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 30) return '${diff.inDays}d';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
  return '${(diff.inDays / 365).floor()}y';
}

String fmtAbsolute(String iso) {
  if (iso.isEmpty) return '';
  DateTime? dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}
