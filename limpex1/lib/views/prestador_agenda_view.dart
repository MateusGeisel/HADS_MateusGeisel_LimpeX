import 'package:flutter/material.dart';

import '../main.dart';
import '../services/solicitacao_service.dart';
import 'avaliar_cliente_view.dart';
import 'perfil_cliente_publico_view.dart';

class PrestadorAgendaView extends StatefulWidget {
  const PrestadorAgendaView({super.key});

  @override
  State<PrestadorAgendaView> createState() => _PrestadorAgendaViewState();
}

class _PrestadorAgendaViewState extends State<PrestadorAgendaView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  List<dynamic> _solicitacoes = [];
  bool _carregando = true;
  String? _erro;
  final Set<int> _respondendo = {};

  @override
  void initState() {
    super.initState();
    _carregarAgenda();
  }

  Future<void> _carregarAgenda() async {
    try {
      final solicitacoes = await _solicitacaoService.buscarAgendaPrestador();
      if (!mounted) return;
      setState(() {
        _solicitacoes = solicitacoes;
        _erro = null;
        _carregando = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar agenda do prestador: $error');
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar sua agenda.';
        _carregando = false;
      });
    }
  }

  Future<void> _responder(
    Map<String, dynamic> solicitacao,
    bool aceitar,
  ) async {
    final id = int.tryParse(solicitacao['id_solicitacao']?.toString() ?? '');
    if (id == null) return;

    if (!aceitar) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recusar solicitação?'),
          content: const Text('O cliente verá que este pedido foi recusado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Recusar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() => _respondendo.add(id));
    final sucesso = aceitar
        ? await _solicitacaoService.aceitarSolicitacao(id)
        : await _solicitacaoService.recusarSolicitacao(id);
    if (!mounted) return;

    setState(() => _respondendo.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? aceitar
                    ? 'Atendimento confirmado na sua agenda.'
                    : 'Solicitação recusada.'
              : 'Não foi possível responder. Atualize a agenda e tente novamente.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
    if (sucesso) await _carregarAgenda();
  }

  Future<void> _concluir(Map<String, dynamic> solicitacao) async {
    final id = int.tryParse(solicitacao['id_solicitacao']?.toString() ?? '');
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar atendimento?'),
        content: const Text(
          'O cliente poderá avaliar o serviço depois da conclusão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Concluir serviço'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _respondendo.add(id));
    final sucesso = await _solicitacaoService.concluirSolicitacao(id);
    if (!mounted) return;

    setState(() => _respondendo.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Atendimento marcado como concluído.'
              : 'Não foi possível concluir o atendimento.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
    if (sucesso) await _carregarAgenda();
  }

  Future<void> _abrirPerfilCliente(int idCliente) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilClientePublicoView(idCliente: idCliente),
      ),
    );
  }

  Future<void> _avaliarCliente(Map<String, dynamic> solicitacao) async {
    final id = int.tryParse(solicitacao['id_solicitacao']?.toString() ?? '');
    if (id == null) return;

    final avaliacaoEnviada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarClienteView(
          idSolicitacao: id,
          nomeCliente:
              solicitacao['nome_cliente']?.toString() ?? 'Cliente LimpeX',
        ),
      ),
    );
    if (!mounted) return;
    if (avaliacaoEnviada == true) await _carregarAgenda();
  }

  String _formatarData(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return 'Data não informada';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de atendimentos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar agenda',
            onPressed: _carregarAgenda,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarAgenda,
        child: _carregando
            ? ListView(
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _erro != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.event_busy, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Center(child: Text(_erro!)),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _carregarAgenda,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                ],
              )
            : _solicitacoes.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.event_available, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Sua agenda ainda não tem atendimentos.')),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Pedidos e atendimentos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (final item in _solicitacoes)
                    _buildSolicitacaoCard(
                      Map<String, dynamic>.from(item as Map),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSolicitacaoCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'PENDENTE';
    final id = int.tryParse(item['id_solicitacao']?.toString() ?? '');
    final idCliente = int.tryParse(item['id_cliente']?.toString() ?? '');
    final respondendo = id != null && _respondendo.contains(id);
    final horario = item['horario_agendamento']?.toString();
    final nomeServico =
        item['nome_servico']?.toString() ??
        item['nome_categoria']?.toString() ??
        'Serviço solicitado';
    final observacoes = (item['descricao_detalhada'] ?? '')
        .toString()
        .replaceAll(
          RegExp(
            r'\n?Horário (solicitado|preferido):\s*\d{2}:\d{2}',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nomeServico,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(status),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: status == 'CONCLUIDO'
                      ? Colors.green.shade100
                      : status == 'ACEITO' || status == 'EM_ANDAMENTO'
                      ? Colors.blue.shade100
                      : status == 'CANCELADO'
                      ? Colors.grey.shade300
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: ClipOval(
                    child:
                        item['foto_perfil_cliente']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? Image.network(
                            item['foto_perfil_cliente'].toString().trim(),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_outline,
                              color: AppTheme.primaryBlue,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryBlue,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['nome_cliente']?.toString() ?? 'Cliente LimpeX',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (idCliente != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _abrirPerfilCliente(idCliente),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Ver perfil do cliente'),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Data: ${_formatarData(item['data_agendamento'])}'
              '${horario == null || horario.isEmpty ? '' : ' às $horario'}',
            ),
            if ((item['bairro'] ?? item['cidade']) != null) ...[
              const SizedBox(height: 4),
              Text(
                '${item['bairro'] ?? 'Bairro não informado'}'
                ' — ${item['cidade'] ?? 'Cidade não informada'}',
              ),
            ],
            if (observacoes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(observacoes, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (status == 'PENDENTE') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: respondendo
                          ? null
                          : () => _responder(item, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: respondendo
                          ? null
                          : () => _responder(item, true),
                      icon: respondendo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'ACEITO' || status == 'EM_ANDAMENTO') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: respondendo ? null : () => _concluir(item),
                  icon: respondendo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt),
                  label: const Text('Marcar como concluído'),
                ),
              ),
            ],
            if (status == 'CONCLUIDO' && item['cliente_avaliado'] != true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: respondendo ? null : () => _avaliarCliente(item),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Avaliar cliente'),
                ),
              ),
            ],
            if (status == 'CONCLUIDO' && item['cliente_avaliado'] == true) ...[
              const SizedBox(height: 8),
              const Text(
                'Cliente avaliado',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
