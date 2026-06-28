import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Client HTTP pentru backend-ul e-Patrimoniu (Render).
///
/// Fiecare cerere include automat token-ul Firebase al utilizatorului curent
/// în header-ul `Authorization: Bearer <idToken>`.
///
/// Utilizare:
///   final users = await ApiService.get('/users');
///   final body  = await ApiService.post('/properties', { ... });
class ApiService {
  static final _base = Uri.parse(AppConfig.backendUrl);

  // ─── Token helper ─────────────────────────────────────────────────────────

  static Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException(401, 'Utilizator neautentificat.');
    return await user.getIdToken() ?? '';
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── Metode HTTP ──────────────────────────────────────────────────────────

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final token = await _idToken();
    final uri   = _base.resolve(path).replace(queryParameters: query);
    final resp  = await http
        .get(uri, headers: _headers(token))
        .timeout(AppConfig.connectionTimeout);
    return _handle(resp);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final token = await _idToken();
    final uri   = _base.resolve(path);
    final resp  = await http
        .post(uri, headers: _headers(token), body: jsonEncode(body))
        .timeout(AppConfig.connectionTimeout);
    return _handle(resp);
  }

  /// Versiune fără autentificare obligatorie — tokenul e adăugat doar dacă
  /// există un utilizator deja autentificat (ex: admin care creează alt cont).
  static Future<dynamic> postPublic(String path, Map<String, dynamic> body) async {
    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {}
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri  = _base.resolve(path);
    final resp = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(AppConfig.connectionTimeout);
    return _handle(resp);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final token = await _idToken();
    final uri   = _base.resolve(path);
    final resp  = await http
        .put(uri, headers: _headers(token), body: jsonEncode(body))
        .timeout(AppConfig.connectionTimeout);
    return _handle(resp);
  }

  static Future<dynamic> delete(String path) async {
    final token = await _idToken();
    final uri   = _base.resolve(path);
    final resp  = await http
        .delete(uri, headers: _headers(token))
        .timeout(AppConfig.connectionTimeout);
    return _handle(resp);
  }

  // ─── Răspuns & erori ─────────────────────────────────────────────────────

  static dynamic _handle(http.Response resp) {
    final body = resp.body.isEmpty ? '{}' : resp.body;
    final json = jsonDecode(body);

    if (resp.statusCode >= 200 && resp.statusCode < 300) return json;

    final msg = (json is Map && json['error'] != null)
        ? json['error'].toString()
        : 'Eroare server (${resp.statusCode})';
    throw ApiException(resp.statusCode, msg);
  }
}

// ─── Excepție personalizată ─────────────────────────────────────────────────

class ApiException implements Exception {
  final int    statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
