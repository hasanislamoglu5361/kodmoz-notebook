import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/credential.dart';
import '../models/model.dart';
import '../models/transformation.dart';
import '../widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, required this.onLogout});

  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  late Future<List<Model>> _models;
  late Future<List<Credential>> _creds;
  late Future<List<Transformation>> _xforms;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _models = widget.api.fetchModels();
      _creds = widget.api.fetchCredentials();
      _xforms = widget.api.fetchTransformations();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.dns_outlined), text: 'Models'),
            Tab(icon: Icon(Icons.vpn_key_outlined), text: 'Credentials'),
            Tab(icon: Icon(Icons.auto_fix_high_outlined), text: 'Transforms'),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ModelList(future: _models),
          _CredList(future: _creds),
          _XformList(future: _xforms),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFCA5A5),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelList extends StatelessWidget {
  const _ModelList({required this.future});
  final Future<List<Model>> future;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => (context as Element).markNeedsBuild(),
      child: FutureBuilder<List<Model>>(
        future: future,
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
          final models = snap.data ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: models.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final m = models[i];
              return Card(
                color: const Color(0xFF161A22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    m.isLanguage
                        ? Icons.chat_outlined
                        : m.isEmbedding
                            ? Icons.scatter_plot_outlined
                            : Icons.volume_up_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(m.name,
                      style: const TextStyle(color: Color(0xFFE5E7EB))),
                  subtitle: Text('${m.provider} • ${m.type}',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                  trailing: StatusBadge(label: m.type),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CredList extends StatelessWidget {
  const _CredList({required this.future});
  final Future<List<Credential>> future;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => (context as Element).markNeedsBuild(),
      child: FutureBuilder<List<Credential>>(
        future: future,
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
          final creds = snap.data ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: creds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = creds[i];
              return Card(
                color: const Color(0xFF161A22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(c.name,
                              style: const TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (c.hasApiKey)
                          const Icon(Icons.check_circle_outline,
                              color: Color(0xFF22C55E), size: 16),
                      ]),
                      const SizedBox(height: 4),
                      Text('${c.provider} • ${c.modalities.join(", ")}',
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12)),
                      if (c.baseUrl != null && c.baseUrl!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(c.baseUrl!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                                fontFamily: 'monospace')),
                      ],
                      const SizedBox(height: 4),
                      Text('${c.modelCount} model(s)',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _XformList extends StatelessWidget {
  const _XformList({required this.future});
  final Future<List<Transformation>> future;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => (context as Element).markNeedsBuild(),
      child: FutureBuilder<List<Transformation>>(
        future: future,
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
          final xs = snap.data ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: xs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final x = xs[i];
              return Card(
                color: const Color(0xFF161A22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: const Color(0xFF6B7280),
                  title: Text(x.title.isEmpty ? x.name : x.title,
                      style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(x.name,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(x.description,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        x.prompt,
                        style: const TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
