import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.sessionStore});

  final String baseUrl;
  final SessionStore sessionStore;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool authenticated = false}) async {
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: await _headers(authenticated), body: jsonEncode(body));
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(Uri.parse('$baseUrl$path'), headers: await _headers(true), body: jsonEncode(body));
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers(true));
    return _decode(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers(true));
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(response.statusCode, _message(response.body));
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers(true));
    return _decode(response);
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await sessionStore.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(response.statusCode, _message(response.body));
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _message(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) {
        final message = value['message'];
        if (message is List) return message.join(', ');
        if (message is String) return message;
      }
    } catch (_) {}
    return 'Falha na comunicação com o servidor';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}
