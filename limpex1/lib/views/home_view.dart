import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/solicitacao_service.dart';
import '../services/prestador_service.dart';
import '../main.dart';
import 'login_view.dart';
import 'add_address_view.dart';
import 'prestador_formalizacao_view.dart';
import 'trilha_mei_view.dart';
import 'criar_solicitacao_view.dart';
import 'avaliar_servico_view.dart';
import 'perfil_prestador_view.dart';
import 'prestador_agenda_view.dart';
import 'meus_servicos_view.dart';
import 'components/service_tags.dart';
import 'search_services_view.dart';

class HomeView extends StatefulWidget {
  final UserModel? user; // 👈 Opcional para aceitar visitantes sem login

  const HomeView({super.key, this.user}); // 👈 Sem o required

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  final PrestadorService _prestadorService = PrestadorService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _buscaController = TextEditingController();
  final GlobalKey _solicitacoesSectionKey = GlobalKey();
  final GlobalKey _servicosDisponiveisSectionKey = GlobalKey();

  List<dynamic> _solicitacoes = [];
  List<dynamic> _servicosDisponiveis = [];
  bool _carregando = false;
  int? _cancelandoSolicitacaoId;
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final isPrestador = widget.user?.tipoPerfil == 'PRESTADOR';

    if (isPrestador) {
      final lista = await _solicitacaoService.buscarSolicitacoesDisponiveis();
      if (mounted) {
        setState(() {
          _solicitacoes = lista;
          _carregando = false;
        });
      }
    } else {
      // Se não houver usuário logado (visitante), busca apenas o catálogo público.
      final listaSolicitacoes = widget.user != null
          ? await _solicitacaoService.buscarMinhasSolicitacoes()
          : [];
      final listaServicos = await _prestadorService.listarServicosDisponiveis();

      if (mounted) {
        setState(() {
          _solicitacoes = listaSolicitacoes;
          _servicosDisponiveis = listaServicos;
          _carregando = false;
        });
      }
    }
  }

  void _fazerLogout(BuildContext context) async {
    final authViewModel = AuthViewModel();
    await authViewModel.logout();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  Future<void> _selecionarNavegacao(int index, bool isPrestador) async {
    setState(() => _selectedNavIndex = index);

    if (!isPrestador && widget.user == null && index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      return;
    }

    if (isPrestador && index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrestadorAgendaView()),
      );
      if (mounted) setState(() => _selectedNavIndex = 0);
      return;
    }

    if (!isPrestador && index == 1) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (index == 0) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final key = isPrestador
        ? _servicosDisponiveisSectionKey
        : _solicitacoesSectionKey;
    final targetContext = key.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  Future<void> _abrirSolicitacao() async {
    if (widget.user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarSolicitacaoView()),
    );
    if (result == true && mounted) {
      _carregarDados();
    }
  }

  Future<void> _abrirAvaliacao(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id_solicitacao']?.toString() ?? '');
    if (id == null) return;

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarServicoView(
          idSolicitacao: id,
          nomePrestador: item['nome_prestador']?.toString() ?? 'prestador',
        ),
      ),
    );
    if (resultado == true && mounted) {
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação registrada. Obrigado!')),
      );
    }
  }

  DateTime? _dataHoraAgendamento(Map<String, dynamic> item) {
    final data = DateTime.tryParse(item['data_agendamento']?.toString() ?? '');
    if (data == null) return null;

    final horario = RegExp(r'^(\d{2}):(\d{2})$')
        .firstMatch(item['horario_agendamento']?.toString() ?? '');
    final hora = int.tryParse(horario?.group(1) ?? '0') ?? 0;
    final minuto = int.tryParse(horario?.group(2) ?? '0') ?? 0;
    if (hora > 23 || minuto > 59) return null;

    return DateTime(data.year, data.month, data.day, hora, minuto);
  }

  bool _podeCancelarSolicitacao(Map<String, dynamic> item) {
    final status = item['status']?.toString();
    if (status != 'PENDENTE' && status != 'ACEITO') return false;
    final agendamento = _dataHoraAgendamento(item);
    return agendamento != null &&
        agendamento.difference(DateTime.now()) >= const Duration(hours: 24);
  }

  Future<void> _confirmarCancelamento(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id_solicitacao']?.toString() ?? '');
    if (id == null || !_podeCancelarSolicitacao(item)) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitação'),
        content: const Text(
          'Deseja cancelar esta solicitação de serviço? Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _cancelandoSolicitacaoId = id);
    String? erro;
    try {
      await _solicitacaoService.cancelarSolicitacao(id);
    } catch (error) {
      erro = error is StateError
          ? error.message.toString()
          : 'Não foi possível cancelar a solicitação. Tente novamente.';
    }
    if (!mounted) return;
    setState(() => _cancelandoSolicitacaoId = null);

    if (erro == null) {
      await _carregarDados();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erro ?? 'Solicitação cancelada com sucesso.'),
        backgroundColor: erro == null ? Colors.green : Colors.red,
      ),
    );
  }

  void _mostrarDetalhesSolicitacao(Map<String, dynamic> item) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['nome_categoria'] ?? 'Serviço de Limpeza',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(item['status'] ?? 'ABERTO'),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cliente: ${item['nome_cliente'] ?? "Cliente LimpeX"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['bairro'] ?? "Bairro não informado"} (${item['cidade'] ?? "Cidade não informada"})',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data: ${_formatarDataAgendamento(item['data_agendamento'])}'
                    '${item['horario_agendamento'] == null ? '' : ' às ${item['horario_agendamento']}'}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Observações:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['descricao_detalhada'] ?? 'Sem observações adicionais.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Recusar'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final id = int.tryParse(
                          item['id_solicitacao']?.toString() ?? '',
                        );
                        if (id == null) return;
                        final sucesso = await _solicitacaoService
                            .recusarSolicitacao(id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              sucesso
                                  ? 'Solicitação recusada.'
                                  : 'Erro ao recusar a solicitação.',
                            ),
                            backgroundColor: sucesso
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                        if (sucesso) _carregarDados();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Aceitar'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final id = int.tryParse(
                          item['id_solicitacao']?.toString() ?? '',
                        );
                        if (id == null) return;
                        final sucesso = await _solicitacaoService
                            .aceitarSolicitacao(id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              sucesso
                                  ? 'Atendimento confirmado na sua agenda.'
                                  : 'Erro ao aceitar o serviço.',
                            ),
                            backgroundColor: sucesso
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                        if (sucesso) _carregarDados();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatarDataAgendamento(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return 'A combinar';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.orange.shade50;
    Color text = Colors.orange.shade800;

    if (status == 'CONCLUIDO') {
      bg = Colors.green.shade50;
      text = Colors.green.shade800;
    } else if (status == 'EM_ANDAMENTO' || status == 'ACEITO') {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade800;
    } else if (status == 'RECUSADO') {
      bg = Colors.red.shade50;
      text = Colors.red.shade800;
    } else if (status == 'CANCELADO') {
      bg = Colors.grey.shade200;
      text = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrestador = widget.user?.tipoPerfil == 'PRESTADOR';
    final String nomeExibicao = widget.user?.nome ?? 'Visitante';
    final Widget homeBody = RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPrestador) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondaryYellow, Color(0xFFFFE082)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryYellow.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.cleaning_services,
                        color: AppTheme.prestadorAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Olá, $nomeExibicao!',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: AppTheme.prestadorAccent,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Painel do prestador de serviços',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildPrestadorDashboard(context),
            ] else ...[
              _buildClienteDashboard(context),
            ],
          ],
        ),
      ),
    );
    final Widget body = isPrestador
        ? homeBody
        : IndexedStack(
            index: _selectedNavIndex == 1 ? 1 : 0,
            children: [
              homeBody,
              SearchServicesView(
                servicos: _servicosDisponiveis,
                controller: _buscaController,
                carregando: _carregando,
                onRefresh: _carregarDados,
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LimpeX — ${isPrestador
              ? "Painel do Prestador"
              : _selectedNavIndex == 1
              ? "Pesquisar Serviços"
              : _selectedNavIndex == 2
              ? "Minhas Solicitações"
              : "Início"}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: Icon(widget.user != null ? Icons.logout : Icons.login),
            tooltip: widget.user != null ? 'Sair' : 'Entrar',
            onPressed: () {
              if (widget.user != null) {
                _fazerLogout(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                );
              }
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: isPrestador
                ? AppTheme.prestadorAccent
                : AppTheme.primaryBlue,
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: isPrestador
              ? AppTheme.secondaryYellow.withValues(alpha: 0.45)
              : AppTheme.primaryBlue.withValues(alpha: 0.12),
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) =>
              _selecionarNavegacao(index, isPrestador),
          destinations: isPrestador
              ? const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline),
                    selectedIcon: Icon(Icons.work),
                    label: 'Disponíveis',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Agenda',
                  ),
                ]
              : widget.user == null
              ? const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    selectedIcon: Icon(Icons.search),
                    label: 'Pesquisar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline),
                    selectedIcon: Icon(Icons.work),
                    label: 'Contratar',
                  ),
                ]
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    selectedIcon: Icon(Icons.search),
                    label: 'Pesquisar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Solicitações',
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildClienteDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Cuidado para sua casa',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.user == null
                    ? 'Sua casa em boas mãos.'
                    : 'Olá, ${widget.user!.nome.split(' ').first}!',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encontre profissionais de limpeza e escolha quem combina com você.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _buscaController,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _selecionarNavegacao(1, false);
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar serviço, profissional ou cidade',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscaController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _abrirSolicitacao,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(
            widget.user == null
                ? 'Entre para contratar um serviço'
                : 'Solicitar um serviço',
          ),
        ),
        if (widget.user != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAddressView()),
              );
            },
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Cadastrar novo endereço'),
          ),
        ],
        if (_servicosDisponiveis.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text(
            'Mais bem avaliados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Serviços de prestadores com as melhores avaliações.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 3 : 2;
              const spacing = 12.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final destaques = _servicosDisponiveis.take(3);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in destaques)
                    _buildServicoCard(
                      Map<String, dynamic>.from(item),
                      cardWidth,
                    ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _selecionarNavegacao(1, false),
          icon: const Icon(Icons.search),
          label: const Text('Pesquisar todos os serviços'),
        ),
        if (widget.user != null) ...[
          const SizedBox(height: 28),
          Text(
            'Minhas Solicitações',
            key: _solicitacoesSectionKey,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_solicitacoes.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: AppTheme.primaryBlue,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _carregando
                            ? 'Carregando suas solicitações...'
                            : 'Você ainda não fez solicitações.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _solicitacoes.length,
              itemBuilder: (context, index) {
                final item = _solicitacoes[index];
                final status = item['status']?.toString() ?? 'PENDENTE';
                final avaliada = item['avaliada'] == true;
                final nota = int.tryParse(
                  item['avaliacao_nota']?.toString() ?? '',
                );
                final comentario =
                    item['avaliacao_comentario']?.toString().trim() ?? '';
                final podeCancelar = _podeCancelarSolicitacao(
                  Map<String, dynamic>.from(item),
                );
                final prazoCancelamentoExpirado =
                    (status == 'PENDENTE' || status == 'ACEITO') &&
                    !podeCancelar;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEAF2FF),
                            child: Icon(
                              Icons.cleaning_services_outlined,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          title: Text(
                            item['nome_servico'] ??
                                item['nome_categoria'] ??
                                'Serviço',
                          ),
                          subtitle: Text(
                            'Data: ${_formatarDataAgendamento(item['data_agendamento'])}'
                            '${item['horario_agendamento'] == null ? '' : ' às ${item['horario_agendamento']}'}'
                            '${item['nome_prestador'] == null ? '' : '\nPrestador: ${item['nome_prestador']}'}',
                          ),
                          trailing: _buildStatusBadge(status),
                        ),
                        if (status == 'CONCLUIDO' && !avaliada)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _abrirAvaliacao(
                                  Map<String, dynamic>.from(item),
                                ),
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Avaliar serviço'),
                              ),
                            ),
                          ),
                        if (status == 'CONCLUIDO' && avaliada) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                for (var estrela = 1; estrela <= 5; estrela++)
                                  Icon(
                                    estrela <= (nota ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: Colors.amber.shade700,
                                  ),
                                const SizedBox(width: 6),
                                Text('${nota ?? 0}/5'),
                              ],
                            ),
                          ),
                          if (comentario.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text(
                                comentario,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                        if (status == 'PENDENTE' || status == 'ACEITO') ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        podeCancelar &&
                                            _cancelandoSolicitacaoId !=
                                                int.tryParse(
                                                  item['id_solicitacao']
                                                          ?.toString() ??
                                                      '',
                                                )
                                        ? () => _confirmarCancelamento(
                                            Map<String, dynamic>.from(item),
                                          )
                                        : null,
                                    icon:
                                        _cancelandoSolicitacaoId ==
                                            int.tryParse(
                                              item['id_solicitacao']
                                                      ?.toString() ??
                                                  '',
                                            )
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancelar solicitação'),
                                  ),
                                ),
                                if (prazoCancelamentoExpirado)
                                  Text(
                                    _dataHoraAgendamento(
                                              Map<String, dynamic>.from(item),
                                            ) ==
                                            null
                                        ? 'Não foi possível verificar o prazo de cancelamento.'
                                        : 'Prazo de cancelamento expirado. É necessário cancelar com pelo menos 24 horas de antecedência.',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
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
      ],
    );
  }

  Widget _buildServicoCard(Map<String, dynamic> item, double width) {
    final nome = (item['nome'] ?? 'Profissional').toString();
    final nomeServico = (item['nome_servico'] ?? 'Serviço').toString();
    final fotosServicos = PrestadorService.extrairFotos(
      item['fotos_servicos'] ?? item['fotos'] ?? item['foto_servico'],
    );
    final fotoServico = fotosServicos.isNotEmpty ? fotosServicos.first : null;
    final fotoPerfil = item['foto_perfil']?.toString();
    final bairro = (item['bairro'] ?? '').toString();
    final cidade = (item['cidade'] ?? '').toString();
    final localizacao = [
      bairro,
      cidade,
    ].where((parte) => parte.trim().isNotEmpty).join(', ');
    final totalAvaliacoes =
        int.tryParse(item['total_avaliacoes']?.toString() ?? '0') ?? 0;
    final idPrestador = int.tryParse(item['id_prestador']?.toString() ?? '');
    final temSelo = item['selo_formalizado'] == true;
    final tipoCobranca = switch (item['tipo_cobranca']?.toString()) {
      'TURNO' => 'por turno',
      'FIXO' => 'por serviço',
      _ => 'por hora',
    };

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: idPrestador == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PerfilPrestadorView(idPrestador: idPrestador),
                    ),
                  );
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: fotoServico != null
                        ? Image.network(
                            fotoServico,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                fotoPerfil != null && fotoPerfil.isNotEmpty
                                ? Image.network(
                                    fotoPerfil,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _buildPrestadorImageFallback(),
                                  )
                                : _buildPrestadorImageFallback(),
                          )
                        : fotoPerfil != null && fotoPerfil.isNotEmpty
                        ? Image.network(
                            fotoPerfil,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildPrestadorImageFallback(),
                          )
                        : _buildPrestadorImageFallback(),
                  ),
                  if (temSelo)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppTheme.primaryBlue,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verificado',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nomeServico,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          totalAvaliacoes == 0
                              ? 'Novo'
                              : '${item['media_nota'] ?? '-'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Prestador: $nome',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ServiceTags(tags: ServiceTags.fromService(item)),
                    if ((item['descricao_servico'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item['descricao_servico'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      'R\$ ${item['valor'] ?? '—'} $tipoCobranca',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (localizacao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        localizacao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      totalAvaliacoes == 0
                          ? 'Ainda sem avaliações'
                          : '$totalAvaliacoes avaliações',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrestadorImageFallback() {
    return Container(
      color: const Color(0xFFEAF2FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.cleaning_services_outlined,
        size: 38,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildPrestadorDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryYellow,
            foregroundColor: AppTheme.textPrimary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeusServicosView()),
            );
          },
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('Gerenciar Meus Serviços'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.prestadorAccent,
            side: const BorderSide(color: AppTheme.secondaryYellow, width: 1.5),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrestadorAgendaView()),
            );
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Abrir Agenda de Atendimentos'),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.prestadorAccent,
            side: const BorderSide(color: AppTheme.secondaryYellow, width: 1.5),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrestadorFormalizacaoView(),
              ),
            );
          },
          icon: const Icon(Icons.verified),
          label: const Text('Cadastrar CNPJ / Formalização MEI'),
        ),
        const SizedBox(height: 10),

        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrilhaMeiView()),
            );
          },
          icon: const Icon(
            Icons.school_outlined,
            color: AppTheme.prestadorAccent,
          ),
          label: const Text(
            'Conhecer Vantagens & Simulador MEI',
            style: TextStyle(
              color: AppTheme.prestadorAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Serviços Disponíveis na Região',
          key: _servicosDisponiveisSectionKey,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else if (_solicitacoes.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: AppTheme.prestadorAccent,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Nenhum serviço disponível no momento na sua região.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _solicitacoes.length,
            itemBuilder: (context, index) {
              final item = _solicitacoes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryYellow.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.work,
                          color: AppTheme.prestadorAccent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nome_categoria'] ?? 'Serviço',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['bairro'] ?? ""} (${item['cidade'] ?? ""})',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryYellow,
                          foregroundColor: AppTheme.textPrimary,
                          minimumSize: const Size(70, 38),
                        ),
                        onPressed: () => _mostrarDetalhesSolicitacao(item),
                        child: const Text(
                          'Ver',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 28),
        const Text(
          'Resumo de Atividades',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.amber.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.prestadorAccent,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Concluídos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'R\$ 0,00',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ganhos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
