import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddAddressView extends StatefulWidget {
  const AddAddressView({Key? key}) : super(key: key);

  @override
  State<AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = AddressService();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _isSearchingCep = false;
  bool _isLoading = false;

  void _buscarCep() async {
    final cep = _cepController.text.trim();
    if (cep.replaceAll(RegExp(r'\D'), '').length != 8) return;

    setState(() => _isSearchingCep = true);

    final data = await _addressService.searchCep(cep);

    setState(() => _isSearchingCep = false);

    if (data != null) {
      setState(() {
        _ruaController.text = data['logradouro'] ?? '';
        _bairroController.text = data['bairro'] ?? '';
        _cidadeController.text = data['localidade'] ?? '';
        _estadoController.text = data['uf'] ?? '';
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não encontrado!'), backgroundColor: Colors.orange),
      );
    }
  }

  void _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final address = AddressModel(
      cep: _cepController.text.trim(),
      rua: _ruaController.text.trim(),
      numero: _numeroController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      // Latitude e longitude serão futuramente obtidos via Geolocator/Google Maps
    );

    final success = await _addressService.saveAddress(address);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço cadastrado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Retorna true para recarregar a lista na Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar endereço.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Endereço')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CEP',
                        hintText: '00000-000',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Informe o CEP' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearchingCep ? null : _buscarCep,
                    child: _isSearchingCep
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Buscar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ruaController,
                decoration: const InputDecoration(labelText: 'Rua / Logradouro'),
                validator: (val) => val == null || val.isEmpty ? 'Informe a rua' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(labelText: 'Número / Complemento'),
                validator: (val) => val == null || val.isEmpty ? 'Informe o número' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bairroController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: (val) => val == null || val.isEmpty ? 'Informe o bairro' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (val) => val == null || val.isEmpty ? 'Informe a cidade' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _estadoController,
                      decoration: const InputDecoration(labelText: 'UF'),
                      validator: (val) => val == null || val.isEmpty ? 'UF' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _salvarEndereco,
                      child: const Text('Salvar Endereço'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}