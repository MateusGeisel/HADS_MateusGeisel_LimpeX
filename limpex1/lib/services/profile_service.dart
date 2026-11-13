import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = 'https://hads-mateusgeisel-limpex.onrender.com';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _request('GET', '$baseUrl/usuarios/me');
    final data = _decodeResponse(response);
    if (response.statusCode != 200 || data is! Map) {
      throw StateError(
        _errorMessage(data, 'Não foi possível carregar o perfil.'),
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String nome,
    required String telefone,
    String? fotoPerfil,
  }) async {
    final response = await _request(
      'PUT',
      '$baseUrl/usuarios/me',
      body: {'nome': nome, 'telefone': telefone, 'foto_perfil': fotoPerfil},
    );
    final data = _decodeResponse(response);
    if (response.statusCode != 200 || data is! Map) {
      throw StateError(
        _errorMessage(data, 'Não foi possível salvar o perfil.'),
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<http.Response> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Entre novamente para editar seu perfil.');
    }

    final uri = Uri.parse(url);
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (method == 'GET') return http.get(uri, headers: headers);
    return http.put(uri, headers: headers, body: jsonEncode(body));
  }

  dynamic _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return null;
    }
  }

  String _errorMessage(dynamic data, String fallback) {
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return fallback;
  }
}
