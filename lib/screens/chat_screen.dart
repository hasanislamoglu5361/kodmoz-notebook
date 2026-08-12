import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/notebook.dart';
import '../models/chat_session.dart';
import '../widgets/format.dart';
import 'chat_session_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<_ChatData> _future;
  String? _filterNotebook;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ChatData> _load() async {
    final nbs = await widget.api.fetchNotebooks(archived: false);
    final sessions = await widget.api.fetchChatSessions(
      notebookId: _filterNotebook,
    );
    return _ChatData(notebooks: nbs, sessions: sessions);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _newSession() async {
    final nbs = (await _future).notebooks;
    if (nbs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Create a notebook first — chat sessions live inside one.')),
      );
      return;
    }
    Notebook selected = nbs.first;
    if (nbs.length > 1 && mounted) {
      final picked = await showModalBottomSheet<Notebook>(
        context: context,
        backgroundColor: const Color(0xFF0F1115),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pick a notebook',
                    style: TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              ...nbs.map((nb) => ListTile(
                    title: Text(nb.name,
                        style: const TextStyle(color: Color(0xFFE5E7EB))),
                    onTap: () => Navigator.pop(ctx, nb),
                  )),
            ],
          ),
        ),
      );
      if (picked == null) return;
      selected = picked;
    }
    if (!mounted) return;
    final t = TextEditingController();
    final created = await showDialog<ChatSession?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New chat session'),
        content: TextField(
          controller: t,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                try {
                  final s = await widget.api.createChatSession(
                    notebookId: selected.id,
                    title: t.text.trim(),
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
        onPressed: _newSession,
        tooltip: 'New chat session',
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<_ChatData>(
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                if (data.notebooks.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _filterNotebook == null,
                            onSelected: (_) {
                              setState(() => _filterNotebook = null);
                              _refresh();
                            },
                          ),
                          const SizedBox(width: 6),
                          ...data.notebooks.map(
                            (nb) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(nb.name),
                                selected: _filterNotebook == nb.id,
                                onSelected: (_) {
                                  setState(() => _filterNotebook = nb.id);
                                  _refresh();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (data.sessions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'No chat sessions yet — tap + to start one.',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  )
                else
                  ...data.sessions.map(
                    (s) => Card(
                      color: const Color(0xFF161A22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFFA855F7)),
                        title: Text(s.title,
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${s.messageCount} msg • ${fmtRelative(s.updated)}',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right,
                            color: Color(0xFF6B7280)),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatSessionScreen(
                                  api: widget.api,
                                  sessionId: s.id,
                                  title: s.title),
                            ),
                          );
                          if (mounted) _refresh();
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatData {
  _ChatData({required this.notebooks, required this.sessions});
  final List<Notebook> notebooks;
  final List<ChatSession> sessions;
}
