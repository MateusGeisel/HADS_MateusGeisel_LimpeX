import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class SolicitacaoService {
  static const String baseUrl =
      'https://hads-mateusgeisel-limpex.onrender.com/solicitacoes';
  final AuthService _authService = AuthService();

  // Criar nova solicitação de limpeza
  Future<bool> criarSolicitacao({
    required int idEndereco,
    required int idCategoria,
    int? idServico,
    required String descricaoDetalhada,
    required String dataAgendamento,
    required String horarioAgendamento,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_servico': idServico,
          'data_agendamento': dataAgendamento,
          'observacoes': descricaoDetalhada,
          'id_endereco': idEndereco,
          'id_categoria': idCategoria,
          'descricao_detalhada': descricaoDetalhada,
          'horario_agendamento': horarioAgendamento,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao criar solicitação: $e');
      return false;
    }
  }

  // Buscar solicitações do cliente autenticado
  Future<List<dynamic>> buscarMinhasSolicitacoes() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/minhas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao buscar solicitações: $e');
    }
    return [];
  }

  // Novo: Buscar solicitações abertas (Feed do Prestador)
  Future<List<dynamic>> buscarSolicitacoesDisponiveis() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/disponiveis'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao buscar solicitações disponíveis: $e');
    }
    return [];
  }

  Future<List<dynamic>> buscarAgendaPrestador() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw StateError('Entre novamente para acessar sua agenda.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/agenda'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Não foi possível carregar a agenda.');
    }

    final dados = jsonDecode(response.body);
    if (dados is! List) {
      throw const FormatException('Resposta inválida ao carregar a agenda.');
    }
    return dados;
  }

  Future<bool> aceitarSolicitacao(int idSolicitacao) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idSolicitacao/aceitar'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao aceitar solicitação: $e');
      return false;
    }
  }

  Future<bool> recusarSolicitacao(int idSolicitacao) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idSolicitacao/recusar'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao recusar solicitação: $e');
      return false;
    }
  }

  Future<bool> concluirSolicitacao(int idSolicitacao) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idSolicitacao/concluir'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao concluir solicitação: $e');
      return false;
    }
  }

  Future<bool> avaliarSolicitacao({
    required int idSolicitacao,
    required int nota,
    String? comentario,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$idSolicitacao/avaliar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nota': nota, 'comentario': comentario}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao avaliar solicitação: $e');
      return false;
    }
  }
}
