import 'package:flutter/material.dart';
import '../services/prestador_service.dart';

class PrestadorFormalizacaoView extends StatefulWidget {
  const PrestadorFormalizacaoView({Key? key}) : super(key: key);

  @override
  State<PrestadorFormalizacaoView> createState() => _PrestadorFormalizacaoViewState();
}

class _PrestadorFormalizacaoViewState extends State<PrestadorFormalizacaoView> {
  final _formKey = GlobalKey<FormState>();
  final _prestadorService = PrestadorService();

  String _tipoDocumento = 'CNPJ'; // 'CPF' ou 'CNPJ'
  bool _optanteMei = true;

  final _documentoController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _inscricaoMunicipalController = TextEditingController();

  bool _isSearching = false;
  bool _isLoading = false;

  void _consultarCnpj() async {
    final cnpj = _documentoController.text.trim();
    if (cnpj.replaceAll(RegExp(r'\D'), '').length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um CNPJ válido com 14 dígitos.')),
      );
      return;
    }

    setState(() => _isSearching = true);

    final dados = await _prestadorService.consultarCnpj(cnpj);

    setState(() => _isSearching = false);

    if (dados != null) {
      setState(() {
        _razaoSocialController.text = dados['razaoSocial'] ?? '';
        _nomeFantasiaController.text = dados['nomeFantasia'] ?? '';
        _optanteMei = dados['optanteMei'] ?? true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da empresa carregados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CNPJ não encontrado ou inválido.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _prestadorService.salvarDadosFiscais(
      tipoDocumento: _tipoDocumento,
      documentoNumero: _documentoController.text,
      razaoSocial: _tipoDocumento == 'CNPJ' ? _razaoSocialController.text : null,
      inscricaoMunicipal: _inscricaoMunicipalController.text.isNotEmpty
          ? _inscricaoMunicipalController.text
          : null,
      optanteMei: _optanteMei,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados fiscais salvos! Seu selo MEI/PJ está em validação.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar dados fiscais.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formalização & Dados Fiscais')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Cadastro Fiscal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'CNPJ', label: Text('Pessoa Jurídica / MEI')),
                  ButtonSegment(value: 'CPF', label: Text('Pessoa Física')),
                ],
                selected: {_tipoDocumento},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _tipoDocumento = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_tipoDocumento == 'CNPJ') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _documentoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ',
                          hintText: '00.000.000/0000-00',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Informe o CNPJ' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      ),
                      onPressed: _isSearching ? null : _consultarCnpj,
                      child: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Buscar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _razaoSocialController,
                  decoration: const InputDecoration(
                    labelText: 'Razão Social (Autopreenchido)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => _tipoDocumento == 'CNPJ' && (val == null || val.isEmpty)
                      ? 'Informe ou busque a Razão Social'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomeFantasiaController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Fantasia',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Optante pelo MEI'),
                  subtitle: const Text('Marque se a sua empresa for Microempreendedor Individual'),
                  value: _optanteMei,
                  onChanged: (val) => setState(() => _optanteMei = val),
                ),
              ] else ...[
                TextFormField(
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: '000.000.000-00',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Informe o CPF' : null,
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _inscricaoMunicipalController,
                decoration: const InputDecoration(
                  labelText: 'Inscrição Municipal (Opcional)',
                  hintText: 'Necessário para emissão de NFS-e',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _salvar,
                      child: const Text('Salvar Dados Fiscais', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}