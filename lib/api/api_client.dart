import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/credential.dart';
import '../models/model.dart';
import '../models/notebook.dart';
import '../models/note.dart';
import '../models/recently_viewed.dart';
import '../models/source.dart';
import '../models/transformation.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  String get displayMessage {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] != null) {
        final d = j['detail'];
        if (d is String) return d;
        if (d is List && d.isNotEmpty) {
          final first = d.first;
          if (first is Map && first['msg'] != null) return first['msg'].toString();
        }
        return d.toString();
      }
    } catch (_) {}
    if (body.isNotEmpty) return body;
    return 'HTTP $statusCode';
  }

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $displayMessage';
}

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? 'https://notebook.kodmoz.com/api';

  final String baseUrl;
  final http.Client _http = http.Client();

  static const _tokenKey = 'kodmoz_notebook_bearer_token';

  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
  }

  Future<String?> loadToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
  }

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

  Future<Map<String, String>> _headers({bool withJson = true}) async {
    final t = await loadToken();
    return {
      if (withJson) 'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool withJson = true,
  }) async {
    final uri = _u(path, query);
    final h = await _headers(withJson: withJson);
    final enc = body == null ? null : jsonEncode(body);
    http.Response r;
    final t = const Duration(seconds: 20);
    switch (method) {
      case 'GET':
        r = await _http.get(uri, headers: h).timeout(t);
        break;
      case 'POST':
        r = await _http
            .post(uri, headers: h, body: enc ?? '')
            .timeout(t);
        break;
      case 'PUT':
        r = await _http
            .put(uri, headers: h, body: enc ?? '')
            .timeout(t);
        break;
      case 'DELETE':
        r = await _http.delete(uri, headers: h).timeout(t);
        break;
      default:
        throw ArgumentError('Unsupported method $method');
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    throw ApiException(r.statusCode, r.body);
  }

  // ─── Auth ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> authStatus() async {
    try {
      return await _request('GET', '/auth/status') as Map<String, dynamic>?;
    } on ApiException {
      return null;
    }
  }

  // ─── Notebooks ───────────────────────────────────────────────────────
  Future<List<Notebook>> fetchNotebooks({bool? archived}) async {
    final q = <String, dynamic>{};
    if (archived != null) q['archived'] = archived.toString();
    final j = await _request('GET', '/notebooks', query: q) as List<dynamic>;
    return j
        .map((e) => Notebook.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Notebook> createNotebook({
    required String name,
    String? description,
  }) async {
    final j = await _request('POST', '/notebooks', body: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    }) as Map<String, dynamic>;
    return Notebook.fromJson(j);
  }

  Future<void> deleteNotebook(String id) async {
    await _request('DELETE', '/notebooks/$id');
  }

  Future<Notebook> updateNotebook({
    required String id,
    String? name,
    String? description,
    bool? archived,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (archived != null) body['archived'] = archived;
    final j = await _request('PUT', '/notebooks/$id', body: body)
        as Map<String, dynamic>;
    return Notebook.fromJson(j);
  }

  Future<List<RecentlyViewedItem>> fetchRecentlyViewed() async {
    final j = await _request('GET', '/notebooks/recently-viewed')
        as List<dynamic>;
    return j
        .map((e) => RecentlyViewedItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ─── Notes ───────────────────────────────────────────────────────────
  Future<List<Note>> fetchNotes({String? notebookId}) async {
    final q = <String, dynamic>{};
    if (notebookId != null && notebookId.isNotEmpty) {
      q['notebook_id'] = notebookId;
    }
    final j = await _request('GET', '/notes', query: q) as List<dynamic>;
    return j
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Note> fetchNote(String id) async {
    final j = await _request('GET', '/notes/$id') as Map<String, dynamic>;
    return Note.fromJson(j);
  }

  Future<Note> createNote({
    required String title,
    required String content,
    required String noteType, // 'human' | 'ai'
  }) async {
    final j = await _request('POST', '/notes', body: {
      'title': title,
      'content': content,
      'note_type': noteType,
    }) as Map<String, dynamic>;
    return Note.fromJson(j);
  }

  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    final j = await _request('PUT', '/notes/$id', body: body)
        as Map<String, dynamic>;
    return Note.fromJson(j);
  }

  Future<void> deleteNote(String id) async {
    await _request('DELETE', '/notes/$id');
  }

  // ─── Sources ─────────────────────────────────────────────────────────
  Future<List<Source>> fetchSources() async {
    final j = await _request('GET', '/sources') as List<dynamic>;
    return j
        .map((e) => Source.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Source> fetchSource(String id) async {
    final j = await _request('GET', '/sources/$id') as Map<String, dynamic>;
    return Source.fromJson(j);
  }

  Future<Source> createSource({
    required String type, // 'link' | 'upload' | 'text'
    String? url,
    String? content,
    String? title,
    String? notebookId,
    bool embed = false,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      if (url != null && url.isNotEmpty) 'url': url,
      if (content != null && content.isNotEmpty) 'content': content,
      if (title != null && title.isNotEmpty) 'title': title,
      if (notebookId != null && notebookId.isNotEmpty)
        'notebook_id': notebookId,
      'embed': embed,
    };
    final j = await _request('POST', '/sources', body: body)
        as Map<String, dynamic>;
    return Source.fromJson(j);
  }

  Future<void> deleteSource(String id) async {
    await _request('DELETE', '/sources/$id');
  }

  // ─── Chat ────────────────────────────────────────────────────────────
  Future<List<ChatSession>> fetchChatSessions({String? notebookId}) async {
    // The Open Notebook chat router requires a notebook_id filter for
    // /chat/sessions — calling without one returns HTTP 422. Pass the
    // notebook id even when listing "all" by leaving the optional arg
    // required in the chat screen.
    final q = <String, dynamic>{};
    if (notebookId != null && notebookId.isNotEmpty) {
      q['notebook_id'] = notebookId;
    }
    final j = await _request('GET', '/chat/sessions', query: q)
        as List<dynamic>;
    return j
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ChatSession> createChatSession({
    required String notebookId,
    String? title,
    String? modelOverride,
  }) async {
    final j = await _request('POST', '/chat/sessions', body: {
      'notebook_id': notebookId,
      if (title != null && title.isNotEmpty) 'title': title,
      if (modelOverride != null && modelOverride.isNotEmpty)
        'model_override': modelOverride,
    }) as Map<String, dynamic>;
    return ChatSession.fromJson(j);
  }

  Future<void> deleteChatSession(String id) async {
    await _request('DELETE', '/chat/sessions/$id');
  }

  Future<List<ChatMessage>> fetchChatMessages(String sessionId) async {
    // The Open Notebook chat router exposes PUT/DELETE for sessions, and POST
    // /chat/execute to send a message. There is no dedicated GET for messages,
    // so we keep this for the rare case the API grows one.
    final raw = await _request(
      'GET',
      '/chat/sessions/$sessionId',
    );
    if (raw is Map<String, dynamic> && raw['messages'] is List) {
      return (raw['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const [];
  }

  Future<List<ChatMessage>> executeChat({
    required String sessionId,
    required String message,
    required Map<String, dynamic> context,
    String? modelOverride,
  }) async {
    final j = await _request('POST', '/chat/execute', body: {
      'session_id': sessionId,
      'message': message,
      'context': context,
      if (modelOverride != null && modelOverride.isNotEmpty)
        'model_override': modelOverride,
    }) as Map<String, dynamic>;
    final list = (j['messages'] as List<dynamic>? ?? const []);
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ─── Transformations ────────────────────────────────────────────────
  Future<List<Transformation>> fetchTransformations() async {
    final j = await _request('GET', '/transformations') as List<dynamic>;
    return j
        .map((e) => Transformation.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ─── Models & Credentials (used by Settings tab) ─────────────────────
  Future<List<Model>> fetchModels() async {
    final j = await _request('GET', '/models') as List<dynamic>;
    return j
        .map((e) => Model.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Credential>> fetchCredentials() async {
    final j = await _request('GET', '/credentials') as List<dynamic>;
    return j
        .map((e) => Credential.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
