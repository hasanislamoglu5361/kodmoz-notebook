import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/note.dart';
import '../widgets/format.dart';
import '../widgets/status_badge.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.api, this.notebookId});
  final ApiClient api;
  final String? notebookId;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<Note>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchNotes(notebookId: widget.notebookId);
  }

  void _refresh() {
    setState(() {
      _future = widget.api.fetchNotes(notebookId: widget.notebookId);
    });
  }

  Future<void> _createNote() async {
    final t = TextEditingController();
    final c = TextEditingController();
    String noteType = 'human';
    final created = await showDialog<Note?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New note'),
        content: StatefulBuilder(builder: (ctx, setSt) {
          return Column(
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
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'human', label: Text('Human')),
                  ButtonSegment(value: 'ai', label: Text('AI')),
                ],
                selected: {noteType},
                onSelectionChanged: (s) => setSt(() => noteType = s.first),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (c.text.trim().isEmpty) return;
                final n = await widget.api.createNote(
                  title: t.text.trim().isEmpty ? 'Untitled' : t.text.trim(),
                  content: c.text,
                  noteType: noteType,
                );
                if (ctx.mounted) Navigator.pop(ctx, n);
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
        onPressed: _createNote,
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Note>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _Err(error: snap.error.toString(), onRetry: _refresh);
            }
            final notes = snap.data ?? const [];
            if (notes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No notes yet — tap + to create one.',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _NoteCard(
                note: notes[i],
                onChanged: _refresh,
                api: widget.api,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.api,
    required this.onChanged,
  });
  final Note note;
  final ApiClient api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _NoteDetailScreen(api: api, noteId: note.id),
            ),
          );
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusBadge(label: note.noteType),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Updated ${fmtRelative(note.updated)}',
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDetailScreen extends StatefulWidget {
  const _NoteDetailScreen({required this.api, required this.noteId});
  final ApiClient api;
  final String noteId;

  @override
  State<_NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<_NoteDetailScreen> {
  late Future<Note> _future;
  bool _editing = false;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchNote(widget.noteId);
  }

  void _startEdit(Note n) {
    _titleCtrl.text = n.title;
    _contentCtrl.text = n.content;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final updated = await widget.api.updateNote(
      id: widget.noteId,
      title: _titleCtrl.text,
      content: _contentCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _editing = false;
      _future = Future.value(updated);
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.api.deleteNote(widget.noteId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          FutureBuilder<Note>(
            future: _future,
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Row(children: [
                if (!_editing)
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _startEdit(snap.data!)),
                IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete),
              ]);
            },
          ),
        ],
      ),
      body: FutureBuilder<Note>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(snap.error.toString(),
                  style: const TextStyle(color: Color(0xFFFCA5A5))),
            );
          }
          final n = snap.data!;
          if (_editing) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _save,
                      child: const Text('Save changes')),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
                StatusBadge(label: n.noteType),
              ]),
              const SizedBox(height: 8),
              Text('Created ${fmtAbsolute(n.created)} • Updated ${fmtRelative(n.updated)}',
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 20),
              SelectableText(
                n.content.isEmpty ? '(empty)' : n.content,
                style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 15,
                    height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Err extends StatelessWidget {
  const _Err({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE5E7EB))),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      ),
    );
  }
}
