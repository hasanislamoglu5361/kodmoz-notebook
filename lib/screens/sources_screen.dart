import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/source.dart';
import '../widgets/format.dart';
import '../widgets/status_badge.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key, required this.api, this.notebookId});
  final ApiClient api;
  final String? notebookId;

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  late Future<List<Source>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchSources();
  }

  void _refresh() {
    setState(() => _future = widget.api.fetchSources());
  }

  Future<void> _createSource() async {
    final t = TextEditingController();
    final u = TextEditingController();
    String type = 'link';
    bool embed = false;

    final created = await showDialog<Source?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add source'),
        content: StatefulBuilder(builder: (ctx, setSt) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'link', label: Text('Link')),
                    ButtonSegment(value: 'text', label: Text('Text')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setSt(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: t,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                if (type == 'link')
                  TextField(
                    controller: u,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'URL'),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Embed for vector search'),
                  value: embed,
                  onChanged: (v) => setSt(() => embed = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (type == 'link' && u.text.trim().isEmpty) return;
                try {
                  final s = await widget.api.createSource(
                    type: type,
                    url: type == 'link' ? u.text.trim() : null,
                    title: t.text.trim(),
                    notebookId: widget.notebookId,
                    embed: embed,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, s);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Create')),
        ],
      ),
    );
    if (created != null && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createSource,
        tooltip: 'Add source',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Source>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFCA5A5))),
                ),
              );
            }
            final sources = snap.data ?? const [];
            if (sources.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(
                  child: Text('No sources yet — tap + to add one.',
                      style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _SourceCard(source: sources[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});
  final Source source;

  IconData get _typeIcon {
    switch (source.type) {
      case 'upload':
        return Icons.upload_file_outlined;
      case 'text':
        return Icons.text_snippet_outlined;
      case 'link':
      default:
        return Icons.link_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_typeIcon,
                  color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(source.title,
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              StatusBadge(label: source.status),
            ]),
            const SizedBox(height: 6),
            if (source.url != null && source.url!.isNotEmpty)
              Text(source.url!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 6),
            Text('Updated ${fmtRelative(source.updated)}',
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
