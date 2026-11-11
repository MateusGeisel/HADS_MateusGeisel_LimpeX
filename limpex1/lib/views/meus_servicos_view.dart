import 'package:flutter/material.dart';

import '../services/prestador_service.dart';
import '../main.dart';
import 'components/image_uploader_widget.dart';

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

  int? _idCategoriaSelecionada;
  List<dynamic> _categorias = [];
  String _tipoCobranca = 'HORA';
  bool _agendaDisponivel = true;
  bool _carregando = false;
  List<dynamic> _servicos = [];

  @override
  void initState() {
    super.initState();
    _carregarMeusServicos();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    _foto1Controller.dispose();
    _foto2Controller.dispose();
    _foto3Controller.dispose();
    super.dispose();
  }

  int? _extrairIdCategoria(dynamic item) {
    if (item == null) return null;
    final rawId = item['id_categoria'] ?? item['id'];
    if (rawId == null) return null;
    return int.tryParse(rawId.toString());
  }

  Future<void> _carregarCategorias() async {
    final cats = await _prestadorService.listarCategorias();
    if (mounted && cats.isNotEmpty) {
      setState(() {
        _categorias = cats;
        _idCategoriaSelecionada = _extrairIdCategoria(cats.first);
      });
    }
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

  void _limparCampos() {
    _nomeController.clear();
    _descricaoController.clear();
    _valorController.clear();
    _foto1Controller.clear();
    _foto2Controller.clear();
    _foto3Controller.clear();
    _tipoCobranca = 'HORA';
    if (_categorias.isNotEmpty) {
      _idCategoriaSelecionada = _extrairIdCategoria(_categorias.first);
    }
  }

  void _abrirModalCadastrarServico() {
    _limparCampos();
    _abrirModalServico();
  }

  void _abrirModalEditarServico(Map<String, dynamic> servico) {
    _nomeController.text = servico['nome']?.toString() ?? '';
    _descricaoController.text = servico['descricao']?.toString() ?? '';
    _valorController.text = servico['valor']?.toString() ?? '';
    _idCategoriaSelecionada = int.tryParse(
      servico['id_categoria']?.toString() ?? '',
    );
    final tipoCobranca = servico['tipo_cobranca']?.toString();
    _tipoCobranca = ['HORA', 'TURNO', 'FIXO'].contains(tipoCobranca)
        ? tipoCobranca!
        : 'HORA';
    final listaFotos = PrestadorService.extrairFotos(
      servico['fotos'] ??
          servico['foto_url'] ??
          servico['imagem_url'] ??
          servico['imagens'],
    );
    _foto1Controller.text = listaFotos.isNotEmpty ? listaFotos[0] : '';
    _foto2Controller.text = listaFotos.length > 1 ? listaFotos[1] : '';
    _foto3Controller.text = listaFotos.length > 2 ? listaFotos[2] : '';
    _abrirModalServico(servico: servico);
  }

  void _abrirModalServico({Map<String, dynamic>? servico}) {
    final editando = servico != null;
    bool salvando = false;

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
                      Text(
                        editando ? 'Editar Serviço' : 'Cadastrar Novo Serviço',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _idCategoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoria do Serviço',
                        ),
                        items: _categorias
                            .map((cat) {
                              final id = _extrairIdCategoria(cat);
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(cat['nome'] ?? 'Categoria'),
                              );
                            })
                            .where((item) => item.value != null)
                            .toList(),
                        validator: (v) =>
                            v == null ? 'Selecione uma categoria' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _idCategoriaSelecionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText:
                              'Nome do Serviço (ex: Instalação de Torneira)',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o nome do serviço'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição / Diferenciais',
                          hintText: 'Descreva seus diferenciais, garantia do trabalho, experiência...',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Descreva o serviço'
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
                              validator: (v) {
                                final valor = double.tryParse(
                                  (v ?? '').replaceAll(',', '.'),
                                );
                                return valor == null || valor <= 0
                                    ? 'Informe um valor válido'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
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
                                DropdownMenuItem(
                                  value: 'FIXO',
                                  child: Text('Valor Fixo'),
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
                        'Fotos do Serviço (Até 3 fotos)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Foto 1'),
                      ImageUploaderWidget(
                        key: ValueKey(
                          '${servico?['id_servico'] ?? 'novo'}-foto1',
                        ),
                        initialImageUrl: _foto1Controller.text.isEmpty
                            ? null
                            : _foto1Controller.text,
                        onImageChanged: (url) =>
                            _foto1Controller.text = url ?? '',
                      ),
                      const SizedBox(height: 12),
                      const Text('Foto 2 (opcional)'),
                      ImageUploaderWidget(
                        key: ValueKey(
                          '${servico?['id_servico'] ?? 'novo'}-foto2',
                        ),
                        initialImageUrl: _foto2Controller.text.isEmpty
                            ? null
                            : _foto2Controller.text,
                        onImageChanged: (url) =>
                            _foto2Controller.text = url ?? '',
                      ),
                      const SizedBox(height: 12),
                      const Text('Foto 3 (opcional)'),
                      ImageUploaderWidget(
                        key: ValueKey(
                          '${servico?['id_servico'] ?? 'novo'}-foto3',
                        ),
                        initialImageUrl: _foto3Controller.text.isEmpty
                            ? null
                            : _foto3Controller.text,
                        onImageChanged: (url) =>
                            _foto3Controller.text = url ?? '',
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
                          onPressed: salvando
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setModalState(() => salvando = true);

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

                                  final valor = double.tryParse(
                                    _valorController.text.replaceAll(',', '.'),
                                  );
                                  final sucesso = editando
                                      ? await _prestadorService
                                            .atualizarServico(
                                              idServico: int.parse(
                                                servico['id_servico']
                                                    .toString(),
                                              ),
                                              idCategoria:
                                                  _idCategoriaSelecionada!,
                                              nome: _nomeController.text.trim(),
                                              descricao: _descricaoController
                                                  .text
                                                  .trim(),
                                              valor: valor!,
                                              tipoCobranca: _tipoCobranca,
                                              fotos: fotos,
                                            )
                                      : await _prestadorService.criarServicoExt(
                                          idCategoria: _idCategoriaSelecionada!,
                                          nome: _nomeController.text.trim(),
                                          descricao: _descricaoController.text
                                              .trim(),
                                          valor: valor!,
                                          tipoCobranca: _tipoCobranca,
                                          fotos: fotos,
                                        );

                                  if (!context.mounted) return;

                                  setModalState(() => salvando = false);

                                  if (sucesso) {
                                    Navigator.pop(context);
                                    _limparCampos();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          editando
                                              ? 'Serviço atualizado com sucesso!'
                                              : 'Serviço cadastrado com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _carregarMeusServicos();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          editando
                                              ? 'Erro ao atualizar serviço no servidor.'
                                              : 'Erro ao cadastrar serviço no servidor.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: salvando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textPrimary,
                                  ),
                                )
                              : Text(
                                  editando
                                      ? 'Salvar Alterações'
                                      : 'Salvar Serviço',
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

  Future<void> _confirmarExclusaoServico(Map<String, dynamic> servico) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir serviço'),
        content: Text('Deseja excluir "${servico['nome']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final idServico = int.tryParse(servico['id_servico']?.toString() ?? '');
    final sucesso =
        idServico != null && await _prestadorService.excluirServico(idServico);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Serviço excluído com sucesso.'
              : 'Não foi possível excluir o serviço.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
    if (sucesso) _carregarMeusServicos();
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
                  final fotos = PrestadorService.extrairFotos(
                    item['fotos'] ??
                        item['foto_url'] ??
                        item['imagem_url'] ??
                        item['imagens'],
                  );

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
                            children: [
                              Expanded(
                                child: Text(
                                  item['nome'] ?? 'Serviço',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'R\$ ${item['valor']} / ${item['tipo_cobranca'] == "TURNO"
                                    ? "Turno"
                                    : item['tipo_cobranca'] == "FIXO"
                                    ? "Fixo"
                                    : "Hora"}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Ações do serviço',
                                onSelected: (acao) {
                                  final dados = Map<String, dynamic>.from(item);
                                  if (acao == 'editar') {
                                    _abrirModalEditarServico(dados);
                                  } else {
                                    _confirmarExclusaoServico(dados);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Editar'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'excluir',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Excluir'),
                                    ),
                                  ),
                                ],
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        fotos[fIndex].toString(),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
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
