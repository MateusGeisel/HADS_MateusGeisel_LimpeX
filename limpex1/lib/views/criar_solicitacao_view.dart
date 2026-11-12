import 'package:flutter/material.dart';

import '../main.dart';
import '../services/prestador_service.dart';
import '../services/solicitacao_service.dart';

class CriarSolicitacaoView extends StatefulWidget {
  final Map<String, dynamic>? servico;

  const CriarSolicitacaoView({super.key, this.servico});

  @override
  State<CriarSolicitacaoView> createState() => _CriarSolicitacaoViewState();
}

class _CriarSolicitacaoViewState extends State<CriarSolicitacaoView> {
  final _formKey = GlobalKey<FormState>();
  final _solicitacaoService = SolicitacaoService();

  final _descricaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _horarioController = TextEditingController();

  int _idCategoriaSelecionada = 1;
  final int _idEnderecoSelecionado = 1; // ID do endereço cadastrado

  bool _carregando = false;

  Future<void> _selecionarData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
      helpText: 'Selecione a data do atendimento',
    );
    if (data != null) {
      _dataController.text =
          '${data.year.toString().padLeft(4, '0')}-'
          '${data.month.toString().padLeft(2, '0')}-'
          '${data.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selecionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecione o horário desejado',
    );
    if (horario != null) {
      _horarioController.text =
          '${horario.hour.toString().padLeft(2, '0')}:'
          '${horario.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void initState() {
    super.initState();
    _idCategoriaSelecionada =
        int.tryParse(widget.servico?['id_categoria']?.toString() ?? '') ?? 1;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _dataController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  void _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate()) return;
    final idServico = int.tryParse(
      widget.servico?['id_servico']?.toString() ?? '',
    );
    if (widget.servico != null && idServico == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o serviço selecionado.'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    final sucesso = await _solicitacaoService.criarSolicitacao(
      idEndereco: _idEnderecoSelecionado,
      idCategoria: _idCategoriaSelecionada,
      idServico: idServico,
      descricaoDetalhada: _descricaoController.text,
      dataAgendamento: _dataController.text,
      horarioAgendamento: _horarioController.text,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retorna true para atualizar a Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar solicitação. Verifique os dados.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servico = widget.servico;
    final fotos = servico == null
        ? <String>[]
        : PrestadorService.extrairFotos(
            servico['fotos'] ??
                servico['foto_url'] ??
                servico['imagem_url'] ??
                servico['imagens'],
          );

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
              if (servico != null) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      if (fotos.isNotEmpty)
                        Image.network(
                          fotos.first,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                width: 90,
                                height: 90,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                        )
                      else
                        const SizedBox(
                          width: 90,
                          height: 90,
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                servico['nome']?.toString() ?? 'Serviço',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${servico['valor'] ?? '—'}',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if ((servico['descricao']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    servico['descricao'].toString(),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ] else
                DropdownButtonFormField<int>(
                  initialValue: _idCategoriaSelecionada,
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('Limpeza Residencial Padrao'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Limpeza Pesada / Pos-Obra'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('Passadoria de Roupas'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _idCategoriaSelecionada = value);
                    }
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
                readOnly: true,
                onTap: _selecionarData,
                decoration: const InputDecoration(
                  hintText: 'Selecione uma data',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Informe a data' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Horario',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _horarioController,
                readOnly: true,
                onTap: _selecionarHorario,
                decoration: const InputDecoration(
                  hintText: 'Selecione um horário',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Informe o horário' : null,
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
                validator: (val) => val == null || val.isEmpty
                    ? 'Descreva o que precisa'
                    : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregando ? null : _enviarSolicitacao,
                  child: _carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirmar Solicitação',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
