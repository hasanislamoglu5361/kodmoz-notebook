import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_session_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sources_screen.dart';

void main() {
  runApp(const KodmozNotebookApp());
}

class KodmozNotebookApp extends StatefulWidget {
  const KodmozNotebookApp({super.key});

  @override
  State<KodmozNotebookApp> createState() => _KodmozNotebookAppState();
}

class _KodmozNotebookAppState extends State<KodmozNotebookApp> {
  final ApiClient _api = ApiClient();
  bool? _hasToken;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final t = await _api.loadToken();
    if (!mounted) return;
    setState(() => _hasToken = t != null && t.isNotEmpty);
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    setState(() => _hasToken = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kodmoz Notebook',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
      ),
      routes: {
        '/chat/session': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as ChatSessionArgs;
          return ChatSessionScreen(
            api: _api,
            sessionId: args.sessionId,
            title: args.title,
          );
        },
      },
      home: _hasToken == null
          ? const _Splash()
          : _hasToken == false
              ? LoginScreen(api: _api, onLoggedIn: _bootstrap)
              : _RootShell(api: _api, onLogout: _logout),
    );
  }
}

class ChatSessionArgs {
  ChatSessionArgs({required this.sessionId, required this.title});
  final String sessionId;
  final String title;
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell({required this.api, required this.onLogout});
  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _idx = 0;
  Key _key = UniqueKey();

  void _refreshAll() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(api: widget.api),
      NotesScreen(api: widget.api),
      SourcesScreen(api: widget.api),
      ChatScreen(api: widget.api),
      SettingsScreen(api: widget.api, onLogout: widget.onLogout),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kodmoz Notebook'),
        actions: [
          IconButton(
              onPressed: _refreshAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: IndexedStack(index: _idx, children: [
        KeyedSubtree(key: ValueKey('home-${_key.hashCode}'), child: pages[0]),
        KeyedSubtree(key: ValueKey('notes-${_key.hashCode}'), child: pages[1]),
        KeyedSubtree(
            key: ValueKey('sources-${_key.hashCode}'), child: pages[2]),
        KeyedSubtree(key: ValueKey('chat-${_key.hashCode}'), child: pages[3]),
        KeyedSubtree(
            key: ValueKey('settings-${_key.hashCode}'), child: pages[4]),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: 'Notes'),
          NavigationDestination(
              icon: Icon(Icons.source_outlined),
              selectedIcon: Icon(Icons.source),
              label: 'Sources'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
