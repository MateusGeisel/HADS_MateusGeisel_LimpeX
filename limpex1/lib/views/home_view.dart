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
import 'perfil_prestador_view.dart';
import 'meus_servicos_view.dart';

class HomeView extends StatefulWidget {
  final UserModel user;

  const HomeView({super.key, required this.user});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  final PrestadorService _prestadorService = PrestadorService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _prestadoresSectionKey = GlobalKey();
  final GlobalKey _solicitacoesSectionKey = GlobalKey();
  final GlobalKey _servicosDisponiveisSectionKey = GlobalKey();

  List<dynamic> _solicitacoes = [];
  List<dynamic> _prestadoresDestaque = [];
  bool _carregando = false;
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    if (widget.user.tipoPerfil == 'PRESTADOR') {
      final lista = await _solicitacaoService.buscarSolicitacoesDisponiveis();
      if (mounted) {
        setState(() {
          _solicitacoes = lista;
          _carregando = false;
        });
      }
    } else {
      final listaSolicitacoes = await _solicitacaoService
          .buscarMinhasSolicitacoes();
      final listaPrestadores = await _prestadorService.listarPrestadores();

      if (mounted) {
        setState(() {
          _solicitacoes = listaSolicitacoes;
          _prestadoresDestaque = listaPrestadores;
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

    if (isPrestador && index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MeusServicosView()),
      );
      if (mounted) {
        setState(() => _selectedNavIndex = 0);
      }
      return;
    }

    if (index == 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    final key = isPrestador
        ? _servicosDisponiveisSectionKey
        : index == 1
        ? _prestadoresSectionKey
        : _solicitacoesSectionKey;
    final targetContext = key.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  void _mostrarDetalhesSolicitacao(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                    'Data: ${item['data_agendamento'] ?? "A combinar"}',
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Aceitar Serviço',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final sucesso = await _solicitacaoService
                        .aceitarSolicitacao(item['id_solicitacao']);
                    if (!mounted) return;
                    if (sucesso) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Serviço aceito com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _carregarDados();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro ao aceitar o serviço.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.orange.shade50;
    Color text = Colors.orange.shade800;

    if (status == 'CONCLUIDO') {
      bg = Colors.green.shade50;
      text = Colors.green.shade800;
    } else if (status == 'EM_ANDAMENTO') {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade800;
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
    final bool isPrestador = widget.user.tipoPerfil == 'PRESTADOR';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LimpeX — ${isPrestador ? "Painel do Prestador" : "Início"}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _fazerLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPrestador
                        ? [AppTheme.secondaryYellow, const Color(0xFFFFE082)]
                        : [AppTheme.primaryBlue, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPrestador
                                  ? AppTheme.secondaryYellow
                                  : AppTheme.primaryBlue)
                              .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        isPrestador ? Icons.cleaning_services : Icons.person,
                        color: isPrestador
                            ? AppTheme.prestadorAccent
                            : AppTheme.primaryBlue,
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
                              Text(
                                'Olá, ${widget.user.nome}!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isPrestador
                                      ? AppTheme.textPrimary
                                      : Colors.white,
                                ),
                              ),
                              if (isPrestador) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: AppTheme.prestadorAccent,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPrestador
                                ? 'Perfil: Prestador de Serviços'
                                : 'Perfil: Cliente LimpeX',
                            style: TextStyle(
                              color: isPrestador
                                  ? AppTheme.textSecondary
                                  : Colors.white.withValues(alpha: 0.9),
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

              if (isPrestador) ...[
                _buildPrestadorDashboard(context),
              ] else ...[
                _buildClienteDashboard(context),
              ],
            ],
          ),
        ),
      ),
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
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Início',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Prestadores',
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
        const Text(
          'O que você precisa hoje?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CriarSolicitacaoView()),
            );
            if (result == true) {
              _carregarDados();
            }
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Solicitar Novo Serviço'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressView()),
            );
          },
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Cadastrar Novo Endereço'),
        ),
        const SizedBox(height: 28),

        Row(
          key: _prestadoresSectionKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prestadores na Sua Região',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('Ver todos')),
          ],
        ),
        const SizedBox(height: 12),
        if (_prestadoresDestaque.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Nenhum prestador disponível na sua região ainda.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _prestadoresDestaque.length,
              itemBuilder: (context, index) {
                final item = _prestadoresDestaque[index];
                final bool temSelo = item['selo_formalizado'] == true;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilPrestadorView(
                          idPrestador: item['id_prestador'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 155,
                    margin: const EdgeInsets.only(right: 14),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.secondaryYellow
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppTheme.prestadorAccent,
                                    size: 30,
                                  ),
                                ),
                                if (temSelo)
                                  const Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.verified,
                                        color: AppTheme.primaryBlue,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['nome'] ?? 'Prestador',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                Text(
                                  ' ${item['media_nota'] ?? "5.0"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 28),
        Text(
          'Minhas Solicitações',
          key: _solicitacoesSectionKey,
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
                  Icon(Icons.history, color: AppTheme.primaryBlue, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nenhum serviço solicitado ainda',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Toque no botão acima para criar seu primeiro pedido.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cleaning_services,
                          color: AppTheme.primaryBlue,
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
                              'Data: ${item['data_agendamento'] ?? "A combinar"}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(item['status'] ?? 'ABERTO'),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
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
          label: const Text('Gerenciar Meus Serviços & Agenda'),
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
