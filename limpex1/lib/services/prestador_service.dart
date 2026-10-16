import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PrestadorService {
  static const String baseUrl = 'http://localhost:3000/prestador';
  final AuthService _authService = AuthService();

  // Buscar dados cadastrais do CNPJ via Backend (BrasilAPI)
  Future<Map<String, dynamic>?> consultarCnpj(String cnpj) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cleanCnpj.length != 14) return null;

    final token = await _authService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cnpj/$cleanCnpj'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao consultar CNPJ no service: $e');
    }
    return null;
  }

  // Salvar dados fiscais (CPF ou CNPJ) no backend
  Future<bool> salvarDadosFiscais({
    required String tipoDocumento,
    required String documentoNumero,
    String? razaoSocial,
    String? inscricaoMunicipal,
    bool optanteMei = false,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dados-fiscais'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipo_documento': tipoDocumento,
          'documento_numero': documentoNumero.replaceAll(RegExp(r'\D'), ''),
          'razao_social': razaoSocial,
          'inscricao_municipal': inscricaoMunicipal,
          'optante_mei': optanteMei,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao salvar dados fiscais: $e');
      return false;
    }
  }

  // Registrar interação na Trilha MEI
  Future<bool> registrarProgressoTrilha(String etapaConcluida) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trilha-mei'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'etapa_concluida': etapaConcluida}),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao registrar progresso MEI: $e');
      return false;
    }
  }
}