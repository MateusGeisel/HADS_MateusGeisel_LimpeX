import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PrestadorService {
  // Ajustado com /prestadores no final para bater com o backend
  static const String baseUrl = 'https://hads-mateusgeisel-limpex.onrender.com/prestadores';
  final AuthService _authService = AuthService();

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

  // Listar todos os prestadores para a Vitrine/Catálogo do Contratante
  Future<List<dynamic>> listarPrestadores() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erro ao listar prestadores: $e');
    }
    return [];
  }

  // Buscar serviços cadastrados do prestador logado
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

  // Listar categorias de serviços disponíveis para cadastro
  Future<List<dynamic>> listarCategorias() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('https://hads-mateusgeisel-limpex.onrender.com/categorias'),
        headers: {'Authorization': 'Bearer $token'},
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

  // Buscar perfil detalhado do prestador e a lista dos seus serviços ofertados
  Future<Map<String, dynamic>?> buscarPerfilPrestador(int idPrestador) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$idPrestador'),
        headers: {'Authorization': 'Bearer $token'},
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