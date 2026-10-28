import 'package:flutter/material.dart';

import '../services/prestador_service.dart';
import '../main.dart';

class MeusServicosView extends StatefulWidget {
  const MeusServicosView({super.key});

  @override
  State<MeusServicosView> createState() => _MeusServicosViewState();
}

class _MeusServicosViewState extends State<MeusServicosView> {
  final PrestadorService _prestadorService = PrestadorService();
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _foto1Controller = TextEditingController();
  final _foto2Controller = TextEditingController();
  final _foto3Controller = TextEditingController();

  final int _idCategoriaSelecionada = 1;
  String _tipoCobranca = 'HORA';
  bool _agendaDisponivel = true;
  bool _carregando = false;
  List<dynamic> _servicos = [];

  @override
  void initState() {
    super.initState();
    _carregarMeusServicos();
  }

  Future<void> _carregarMeusServicos() async {
    setState(() => _carregando = true);
    final lista = await _prestadorService.listarMeusServicos();
    if (mounted) {
      setState(() {
        _servicos = lista;
        _carregando = false;
      });
    }
  }

  void _abrirModalCadastrarServico() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastrar Novo Serviço',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Serviço (ex: Limpeza Pesada)',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição / Diferenciais',
                          hintText: 'Descreva seus diferenciais, capricho, experiência...',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Descreva seu serviço'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _valorController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Valor (R\$)',
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Informe o valor'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _tipoCobranca,
                              decoration: const InputDecoration(
                                labelText: 'Cobrança Por',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'HORA',
                                  child: Text('Por Hora'),
                                ),
                                DropdownMenuItem(
                                  value: 'TURNO',
                                  child: Text('Por Turno'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => _tipoCobranca = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'URLs das Fotos do Serviço (Até 3 fotos)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _foto1Controller,
                        decoration: const InputDecoration(
                          labelText: 'URL da Foto 1',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _foto2Controller,
                        decoration: const InputDecoration(
                          labelText: 'URL da Foto 2 (Opcional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _foto3Controller,
                        decoration: const InputDecoration(
                          labelText: 'URL da Foto 3 (Opcional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryYellow,
                            foregroundColor: AppTheme.textPrimary,
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            List<String> fotos = [];
                            if (_foto1Controller.text.isNotEmpty) {
                              fotos.add(_foto1Controller.text.trim());
                            }
                            if (_foto2Controller.text.isNotEmpty) {
                              fotos.add(_foto2Controller.text.trim());
                            }
                            if (_foto3Controller.text.isNotEmpty) {
                              fotos.add(_foto3Controller.text.trim());
                            }

                            final sucesso = await _prestadorService
                                .criarServicoExt(
                                  idCategoria: _idCategoriaSelecionada,
                                  nome: _nomeController.text.trim(),
                                  descricao: _descricaoController.text.trim(),
                                  valor:
                                      double.tryParse(
                                        _valorController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0.0,
                                  tipoCobranca: _tipoCobranca,
                                  fotos: fotos,
                                );

                            if (!mounted) return;
                            Navigator.pop(context);

                            if (sucesso) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Serviço cadastrado com sucesso!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _carregarMeusServicos();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro ao cadastrar serviço.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Salvar Serviço',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Serviços & Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryYellow,
        foregroundColor: AppTheme.textPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Serviço',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _abrirModalCadastrarServico,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Configuração da Agenda
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                activeThumbColor: AppTheme.prestadorAccent,
                title: const Text(
                  'Agenda Aberta no Aplicativo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _agendaDisponivel
                      ? 'Clientes podem agendar horários diretamente pelo app.'
                      : 'Sua agenda está oculta. O contato será tratado via Chat.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                value: _agendaDisponivel,
                onChanged: (val) async {
                  setState(() => _agendaDisponivel = val);
                  await _prestadorService.atualizarStatusAgenda(val);
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Serviços Ofertados por Você',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_servicos.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Você ainda não cadastrou nenhum serviço. Toque no botão abaixo para adicionar!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _servicos.length,
                itemBuilder: (context, index) {
                  final item = _servicos[index];
                  final List<dynamic> fotos = item['fotos'] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['nome'] ?? 'Serviço',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${item['valor']} / ${item['tipo_cobranca'] == "TURNO" ? "Turno" : "Hora"}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (item['descricao'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              item['descricao'],
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (fotos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length,
                                itemBuilder: (context, fIndex) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(fotos[fIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
