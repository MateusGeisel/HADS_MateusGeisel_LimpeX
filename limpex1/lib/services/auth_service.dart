import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3000/auth';

  // Salvar Token e Dados do Usuário
  Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Buscar Token Salvo
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Buscar Usuário Salvo
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Encerrar Sessão (Logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
    String? cpf,
    String? telefone,
    String tipoPerfil = 'CLIENTE',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'cpf': cpf,
        'telefone': telefone,
        'tipo_perfil': tipoPerfil,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Erro no cadastro.'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);
      
      // Salva a sessão localmente no Login
      await saveSession(token, user);

      return {'success': true, 'token': token, 'user': user};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Credenciais inválidas.'};
    }
  }
}