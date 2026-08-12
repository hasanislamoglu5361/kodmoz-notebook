// Integration smoke test — verify the app's models parse real API responses.
// Run with: dart run test/integration_smoke.dart
import 'dart:convert';
import 'dart:io';

import '../lib/models/notebook.dart';
import '../lib/models/note.dart';
import '../lib/models/source.dart';
import '../lib/models/chat_session.dart';
import '../lib/models/chat_message.dart';
import '../lib/models/transformation.dart';
import '../lib/models/model.dart';
import '../lib/models/credential.dart';

Future<List<dynamic>> _get(String base, String ep,
    {Map<String, String>? query}) async {
  final uri = Uri.parse('$base$ep').replace(queryParameters: query);
  final r = await HttpClient().getUrl(uri).then((req) {
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer Kodmoz!!2026!!');
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    return req.close();
  });
  final body = await r.transform(utf8.decoder).join();
  return [r.statusCode, body];
}

void main() async {
  final base = 'https://notebook.kodmoz.com/api';
  var failed = 0;

  Future<void> check(String name, String ep,
      {Map<String, String>? query, Function(Map<String, dynamic>)? probe}) async {
    final result = await _get(base, ep, query: query);
    final code = result[0] as int;
    final body = result[1] as String;
    if (code != 200) {
      print('FAIL $name  HTTP $code');
      failed++;
      return;
    }
    try {
      final list = jsonDecode(body) as List<dynamic>;
      if (list.isEmpty) {
        print('OK   $name  HTTP 200, empty list');
        return;
      }
      if (probe != null) {
        probe(list.first as Map<String, dynamic>);
      } else {
        print('OK   $name  HTTP 200, ${list.length} items');
      }
    } catch (e) {
      print('FAIL $name  parse error: $e');
      failed++;
    }
  }

  await check('notebooks', '/notebooks', probe: (m) {
    final n = Notebook.fromJson(m);
    print('OK   notebooks  → ${n.name} (sources=${n.sourceCount})');
  });
  await check('notes', '/notes', probe: (m) {
    final n = Note.fromJson(m);
    print('OK   notes  → "${n.title}" type=${n.noteType}');
  });
  await check('sources', '/sources');
  await check('models', '/models', probe: (m) {
    final x = Model.fromJson(m);
    print('OK   models  → ${x.name} (${x.type})');
  });
  await check('credentials', '/credentials', probe: (m) {
    final c = Credential.fromJson(m);
    print('OK   credentials  → ${c.name}');
  });
  await check('transformations', '/transformations', probe: (m) {
    final t = Transformation.fromJson(m);
    print('OK   transformations  → "${t.title}" prompt=${t.prompt.length} chars');
  });
  await check('chat_sessions', '/chat/sessions',
      query: {'notebook_id': 'notebook:2dyhmmcj525amtb69g8n'},
      probe: (m) {
    final s = ChatSession.fromJson(m);
    print('OK   chat_sessions  → "${s.title}" msgs=${s.messageCount}');
    // also test ChatMessage.fromJson with a synthetic body
    final msg = ChatMessage.fromJson({'role': 'user', 'content': 'hi'});
    assert(msg.isUser);
  });

  if (failed > 0) {
    print('FAILED $failed endpoint(s)');
    exit(1);
  }
  print('ALL OK');
}
