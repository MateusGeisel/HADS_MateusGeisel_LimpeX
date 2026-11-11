import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PrestadorService {
  // Ajustado com /prestadores no final para bater com o backend
  static const String baseUrl =
      'https://hads-mateusgeisel-limpex.onrender.com/prestadores';
  final AuthService _authService = AuthService();

  static List<String> extrairFotos(dynamic fotos) {
    dynamic valores = fotos;
    if (fotos is String) {
      final texto = fotos.trim();
      if (texto.isEmpty) return [];

      if (texto.startsWith('[')) {
        try {
          valores = jsonDecode(texto);
        } on FormatException {
          return [];
        }
      } else if (texto.startsWith('{') && texto.endsWith('}')) {
        valores = texto
            .substring(1, texto.length - 1)
            .split(',')
            .map((valor) => valor.trim().replaceAll('"', ''))
            .where((valor) => valor.isNotEmpty)
            .toList();
      } else {
        valores = [texto];
      }
    }

    if (valores is! List) return [];
    return valores
        .map((valor) {
          if (valor is Map) {
            return (valor['url'] ?? valor['publicUrl'] ?? '').toString();
          }
          return valor.toString();
        })
        .where((url) {
          final uri = Uri.tryParse(url);
          return uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty;
        })
        .toList();
  }

  // ==========================================
  // FUNCIONALIDADES EXISTENTES (MEI / FISCAL)
  // ==========================================

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

  // ==========================================
  // NOVAS FUNCIONALIDADES (VITRINE & SERVIÇOS)
  // ==========================================

  // 🟢 PÚBLICO: Listar todos os prestadores para a Vitrine/Catálogo do Contratante
  Future<List<dynamic>> listarPrestadores() async {
    final token = await _authService.getToken();

    final Map<String, String> headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao listar prestadores: $e');
    }
    return [];
  }

  // Buscar serviços cadastrados do prestador logado (PROTEGIDO)
  Future<List<dynamic>> listarMeusServicos() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/servicos/meus'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao listar meus serviços: $e');
    }
    return [];
  }

  // Método de criação estendida com Fotos e Tipo de Cobrança
  Future<bool> criarServicoExt({
    required int idCategoria,
    required String nome,
    String? descricao,
    required double valor,
    String tipoCobranca = 'HORA',
    List<String>? fotos,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/servicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_categoria': idCategoria,
          'nome': nome,
          'descricao': descricao,
          'valor': valor,
          'tipo_cobranca': tipoCobranca,
          'fotos': fotos ?? [],
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao criar serviço estendido: $e');
      return false;
    }
  }

  Future<bool> atualizarServico({
    required int idServico,
    required int idCategoria,
    required String nome,
    String? descricao,
    required double valor,
    required String tipoCobranca,
    required List<String> fotos,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/servicos/$idServico'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '******',
        },
        body: jsonEncode({
          'id_categoria': idCategoria,
          'nome': nome,
          'descricao': descricao,
          'valor': valor,
          'tipo_cobranca': tipoCobranca,
          'fotos': fotos,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao atualizar serviço: $e');
      return false;
    }
  }

  Future<bool> excluirServico(int idServico) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/servicos/$idServico'),
        headers: {'Authorization': '******'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao excluir serviço: $e');
      return false;
    }
  }

  // Listar categorias de serviços disponíveis para cadastro
  Future<List<dynamic>> listarCategorias() async {
    final token = await _authService.getToken();

    final Map<String, String> headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(
        Uri.parse('https://hads-mateusgeisel-limpex.onrender.com/categorias'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao buscar categorias: $e');
    }
    return [];
  }

  // Alternar agenda aberta/fechada no aplicativo
  Future<bool> atualizarStatusAgenda(bool agendaDisponivel) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/agenda'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'agenda_disponivel': agendaDisponivel}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao atualizar status da agenda: $e');
      return false;
    }
  }

  // 🟢 PÚBLICO: Buscar perfil detalhado do prestador e a lista dos seus serviços ofertados
  Future<Map<String, dynamic>?> buscarPerfilPrestador(int idPrestador) async {
    final token = await _authService.getToken();

    final Map<String, String> headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$idPrestador'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao buscar perfil do prestador: $e');
    }
    return null;
  }

  // Prestador cadastrar um novo serviço para exibir no seu perfil
  Future<bool> criarServico({
    required int idCategoria,
    required String nome,
    String? descricao,
    required double valor,
    String modalidade = 'DOMICILIO',
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/servicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_categoria': idCategoria,
          'nome': nome,
          'descricao': descricao,
          'valor': valor,
          'modalidade': modalidade,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao criar serviço: $e');
      return false;
    }
  }
}
