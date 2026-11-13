import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/address_model.dart';
import 'auth_service.dart';

class AddressService {
  static const String baseUrl =
      'https://hads-mateusgeisel-limpex.onrender.com/address';
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
      debugPrint('Erro ao consultar ViaCEP: $e');
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

  Future<AddressModel> createAddress(AddressModel address) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw StateError('Entre novamente para salvar seu endereço.');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(address.toJson()),
    );
    if (response.statusCode != 201) {
      throw StateError('Não foi possível salvar o endereço.');
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['address'] is! Map) {
      throw const FormatException('Resposta inválida ao salvar o endereço.');
    }
    return AddressModel.fromJson(
      Map<String, dynamic>.from(data['address'] as Map),
    );
  }

  // Listar endereços do usuário logado
  Future<List<AddressModel>> getAddresses() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw StateError('Entre novamente para acessar seus endereços.');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => AddressModel.fromJson(item)).toList();
    }
    throw StateError('Não foi possível carregar seus endereços.');
  }

  Future<bool> updateAddress(AddressModel address) async {
    final token = await _authService.getToken();
    final idEndereco = address.idEndereco;
    if (token == null || idEndereco == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/$idEndereco'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(address.toJson()),
    );

    return response.statusCode == 200;
  }
}
