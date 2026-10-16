import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import 'auth_service.dart';

class AddressService {
  static const String baseUrl = 'http://localhost:3000/address';
  final AuthService _authService = AuthService();

  // Buscar dados de rua/bairro/cidade pelo ViaCEP
  Future<Map<String, dynamic>?> searchCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) return null;

    final url = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) return null;
        return data;
      }
    } catch (e) {
      print('Erro ao consultar ViaCEP: $e');
    }
    return null;
  }

  // Cadastrar novo endereço no backend
  Future<bool> saveAddress(AddressModel address) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(address.toJson()),
    );

    return response.statusCode == 201;
  }

  // Listar endereços do usuário logado
  Future<List<AddressModel>> getAddresses() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => AddressModel.fromJson(item)).toList();
    }
    return [];
  }
}