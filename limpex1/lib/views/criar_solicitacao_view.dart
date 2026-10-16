import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';

class CriarSolicitacaoView extends StatefulWidget {
  const CriarSolicitacaoView({Key? key}) : super(key: key);

  @override
  State<CriarSolicitacaoView> createState() => _CriarSolicitacaoViewState();
}

class _CriarSolicitacaoViewState extends State<CriarSolicitacaoView> {
  final _formKey = GlobalKey<FormState>();
  final _solicitacaoService = SolicitacaoService();

  final _descricaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _horarioController = TextEditingController();

  // Valores mocados de ID para teste inicial (serão dinâmicos com a busca de endereços e categorias)
  int _idCategoriaSelecionada = 1; // Ex: 1 = Limpeza Residencial
  int _idEnderecoSelecionado = 1;  // ID do endereço cadastrado

  bool _carregando = false;

  void _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    final sucesso = await _solicitacaoService.criarSolicitacao(
      idEndereco: _idEnderecoSelecionado,
      idCategoria: _idCategoriaSelecionada,
      descricaoDetalhada: _descricaoController.text,
      dataAgendamento: _dataController.text,
      horarioAgendamento: _horarioController.text,
    );

    setState(() => _carregando = false);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação criada com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Retorna true para atualizar a Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar solicitação. Verifique os dados.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Nova Limpeza')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Serviço',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _idCategoriaSelecionada,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Limpeza Residencial Padrao')),
                  DropdownMenuItem(value: 2, child: Text('Limpeza Pesada / Pos-Obra')),
                  DropdownMenuItem(value: 3, child: Text('Passadoria de Roupas')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _idCategoriaSelecionada = value);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cleaning_services),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Data do Agendamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dataController,
                decoration: const InputDecoration(
                  hintText: 'AAAA-MM-DD (Ex: 2026-10-15)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Informe a data' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Horario',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _horarioController,
                decoration: const InputDecoration(
                  hintText: 'HH:MM (Ex: 08:00)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Informe o horário' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Detalhes da Solicitação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ex: Apartamento 2 quartos, dar atenção especial para a cozinha...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Descreva o que precisa' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _carregando ? null : _enviarSolicitacao,
                  child: _carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar Solicitação', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}