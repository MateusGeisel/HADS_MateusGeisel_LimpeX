import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;
  String? token;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Verifica se já existe um token salvo ao abrir o app
  Future<bool> checkAutoLogin() async {
    _setLoading(true);
    final savedToken = await _authService.getToken();
    final savedUser = await _authService.getUser();

    if (savedToken != null && savedUser != null) {
      token = savedToken;
      currentUser = savedUser;
      _setLoading(false);
      return true; // Usuário já está logado
    }

    _setLoading(false);
    return false; // Precisa fazer login
  }

  Future<bool> register({
    required String nome,
    required String email,
    required String senha,
    String? cpf,
    String? telefone,
    String tipoPerfil = 'CLIENTE',
  }) async {
    _setLoading(true);
    errorMessage = null;

    final result = await _authService.register(
      nome: nome,
      email: email,
      senha: senha,
      cpf: cpf,
      telefone: telefone,
      tipoPerfil: tipoPerfil,
    );

    _setLoading(false);

    if (result['success']) {
      return true;
    } else {
      errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String senha) async {
    _setLoading(true);
    errorMessage = null;

    final result = await _authService.login(email: email, senha: senha);

    _setLoading(false);

    if (result['success']) {
      currentUser = result['user'];
      token = result['token'];
      notifyListeners();
      return true;
    } else {
      errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearSession();
    currentUser = null;
    token = null;
    notifyListeners();
  }
}