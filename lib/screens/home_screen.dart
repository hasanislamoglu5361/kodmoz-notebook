import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/notebook.dart';
import '../models/recently_viewed.dart';
import '../widgets/format.dart';
import '../widgets/stat_tile.dart';
import 'notebook_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final nbs = await widget.api.fetchNotebooks(archived: false);
    List<RecentlyViewedItem> recent = const [];
    try {
      recent = await widget.api.fetchRecentlyViewed();
    } catch (_) {
      // /notebooks/recently-viewed is best-effort; ignore failures.
    }
    final totalSources =
        nbs.fold<int>(0, (a, n) => a + n.sourceCount);
    final totalNotes = nbs.fold<int>(0, (a, n) => a + n.noteCount);
    return _HomeData(
      notebooks: nbs,
      recent: recent,
      totalSources: totalSources,
      totalNotes: totalNotes,
    );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _createNotebook() async {
    final c = TextEditingController();
    final d = TextEditingController();
    final created = await showDialog<Notebook?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New notebook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: d,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (c.text.trim().isEmpty) return;
                final nb = await widget.api
                    .createNotebook(name: c.text.trim(), description: d.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, nb);
              },
              child: const Text('Create')),
        ],
      ),
    );
    if (created != null && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              error: snap.error.toString(),
              onRetry: _refresh,
            );
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Notebooks',
                      value: data.notebooks.length.toString(),
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'Sources',
                      value: data.totalSources.toString(),
                      icon: Icons.source_outlined,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Notes',
                      value: data.totalNotes.toString(),
                      icon: Icons.sticky_note_2_outlined,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'Recently viewed',
                      value: data.recent.length.toString(),
                      icon: Icons.history_outlined,
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notebooks',
                      style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _createNotebook,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.notebooks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161A22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'No notebooks yet — tap “New” to create one.',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else
                ...data.notebooks.map(
                  (nb) => _NotebookCard(
                    nb: nb,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotebookDetailScreen(
                              api: widget.api, notebookId: nb.id),
                        ),
                      );
                      if (mounted) _refresh();
                    },
                  ),
                ),
              if (data.recent.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Recently viewed',
                  style: TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...data.recent.map((r) => Card(
                      color: const Color(0xFF161A22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          r.isNotebook
                              ? Icons.menu_book_outlined
                              : Icons.source_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(r.title,
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB), fontSize: 14)),
                        subtitle: Text(fmtRelative(r.lastViewedAt),
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HomeData {
  _HomeData({
    required this.notebooks,
    required this.recent,
    required this.totalSources,
    required this.totalNotes,
  });
  final List<Notebook> notebooks;
  final List<RecentlyViewedItem> recent;
  final int totalSources;
  final int totalNotes;
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.nb, required this.onTap});
  final Notebook nb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A22),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nb.name,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (nb.archived)
                    const Icon(Icons.archive_outlined,
                        size: 16, color: Color(0xFF9CA3AF)),
                ],
              ),
              if (nb.description != null && nb.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nb.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.source_outlined,
                      size: 14, color: const Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text('${nb.sourceCount}',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(width: 14),
                  Icon(Icons.sticky_note_2_outlined,
                      size: 14, color: const Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text('${nb.noteCount}',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                  const Spacer(),
                  Text(
                    fmtRelative(nb.updated),
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE5E7EB)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
