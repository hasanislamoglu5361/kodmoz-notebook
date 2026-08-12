import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/note.dart';
import '../models/source.dart';
import '../widgets/format.dart';

class NotebookDetailScreen extends StatefulWidget {
  const NotebookDetailScreen({
    super.key,
    required this.api,
    required this.notebookId,
  });

  final ApiClient api;
  final String notebookId;

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final notes = await widget.api.fetchNotes(notebookId: widget.notebookId);
    final sources = await widget.api
        .fetchSources()
        .then((all) => all
            .where((s) => s.notebookIds.contains(widget.notebookId))
            .toList());
    return _DetailData(notes: notes, sources: sources);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.sticky_note_2_outlined), text: 'Notes'),
            Tab(icon: Icon(Icons.source_outlined), text: 'Sources'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_DetailData>(
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
          final data = snap.data!;
          return TabBarView(
            controller: _tab,
            children: [
              _NotesList(
                  notes: data.notes,
                  api: widget.api,
                  notebookId: widget.notebookId,
                  onChanged: _refresh),
              _SourcesList(sources: data.sources),
              _ChatLauncher(
                  api: widget.api, notebookId: widget.notebookId),
            ],
          );
        },
      ),
    );
  }
}

class _DetailData {
  _DetailData({required this.notes, required this.sources});
  final List<Note> notes;
  final List<Source> sources;
}

class _NotesList extends StatefulWidget {
  const _NotesList({
    required this.notes,
    required this.api,
    required this.notebookId,
    required this.onChanged,
  });
  final List<Note> notes;
  final ApiClient api;
  final String notebookId;
  final VoidCallback onChanged;

  @override
  State<_NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<_NotesList> {
  Future<void> _add() async {
    final t = TextEditingController();
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New note in this notebook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: t,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              maxLines: 6,
              decoration: const InputDecoration(
                  labelText: 'Content', alignLabelWithHint: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (c.text.trim().isEmpty) return;
                await widget.api.createNote(
                  title: t.text.trim().isEmpty ? 'Untitled' : t.text.trim(),
                  content: c.text,
                  noteType: 'human',
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && mounted) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No notes yet.',
                style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Add note')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => widget.onChanged(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: widget.notes.length + 1,
        separatorBuilder: (_, i) =>
            i == widget.notes.length ? const SizedBox.shrink() : const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i == widget.notes.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Add note'),
                ),
              ),
            );
          }
          final n = widget.notes[i];
          return Card(
            color: const Color(0xFF161A22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(n.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Updated ${fmtRelative(n.updated)}',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SourcesList extends StatelessWidget {
  const _SourcesList({required this.sources});
  final List<Source> sources;
  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Center(
        child: Text('No sources attached yet.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final s = sources[i];
        return Card(
          color: const Color(0xFF161A22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.source_outlined,
                color: Color(0xFF22C55E)),
            title: Text(s.title,
                style: const TextStyle(color: Color(0xFFE5E7EB))),
            subtitle: Text(
                '${s.type} • ${s.status} • ${fmtRelative(s.updated)}',
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _ChatLauncher extends StatefulWidget {
  const _ChatLauncher({required this.api, required this.notebookId});
  final ApiClient api;
  final String notebookId;
  @override
  State<_ChatLauncher> createState() => _ChatLauncherState();
}

class _ChatLauncherState extends State<_ChatLauncher> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchChatSessions(notebookId: widget.notebookId);
  }

  Future<void> _start() async {
    final s = await widget.api
        .createChatSession(notebookId: widget.notebookId);
    if (!mounted) return;
    setState(() => _future = widget.api
        .fetchChatSessions(notebookId: widget.notebookId));
    if (s.id.isNotEmpty) {
      // ignore: use_build_context_synchronously
      await Navigator.pushNamed(context, '/chat/${s.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          setState(() => _future = widget.api
              .fetchChatSessions(notebookId: widget.notebookId)),
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = (snap.data ?? const []).cast();
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Start new chat session')),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161A22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('No sessions yet.',
                        style: TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                )
              else
                ...list.map((s) => Card(
                      color: const Color(0xFF161A22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFFA855F7)),
                        title: Text(s.title,
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB), fontSize: 14)),
                        subtitle: Text('${s.messageCount} msg',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
