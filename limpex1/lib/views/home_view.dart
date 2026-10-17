import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/solicitacao_service.dart';
import '../services/prestador_service.dart';
import 'login_view.dart';
import 'add_address_view.dart';
import 'prestador_formalizacao_view.dart';
import 'trilha_mei_view.dart';
import 'criar_solicitacao_view.dart';
import 'perfil_prestador_view.dart';
import 'meus_servicos_view.dart';

class HomeView extends StatefulWidget {
  final UserModel user;

  const HomeView({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  final PrestadorService _prestadorService = PrestadorService();

  List<dynamic> _solicitacoes = [];
  List<dynamic> _prestadoresDestaque = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    if (widget.user.tipoPerfil == 'PRESTADOR') {
      final lista = await _solicitacaoService.buscarSolicitacoesDisponiveis();
      setState(() {
        _solicitacoes = lista;
        _carregando = false;
      });
    } else {
      final listaSolicitacoes = await _solicitacaoService
          .buscarMinhasSolicitacoes();
      final listaPrestadores = await _prestadorService.listarPrestadores();

      setState(() {
        _solicitacoes = listaSolicitacoes;
        _prestadoresDestaque = listaPrestadores;
        _carregando = false;
      });
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

  void _mostrarDetalhesSolicitacao(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['nome_categoria'] ?? 'Serviço de Limpeza',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(item['status'] ?? 'PENDENTE'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${item['nome_cliente'] ?? "Cliente LimpeX"}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Localização: ${item['bairro'] ?? "Bairro não informado"} (${item['cidade'] ?? "Cidade não informada"})',
              ),
              const SizedBox(height: 4),
              Text('Data do Agendamento: ${item['data_agendamento']}'),
              const SizedBox(height: 8),
              const Text(
                'Observações:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                item['descricao_detalhada'] ?? 'Sem observações adicionais.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Aceitar Serviço',
                    style: TextStyle(fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final bool isPrestador = widget.user.tipoPerfil == 'PRESTADOR';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LimpeX - ${isPrestador ? "Painel do Prestador" : "Início"}',
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Boas-Vindas
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isPrestador
                            ? Colors.orange
                            : Colors.blue,
                        child: Icon(
                          isPrestador ? Icons.cleaning_services : Icons.person,
                          color: Colors.white,
                          size: 30,
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isPrestador) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPrestador
                                  ? 'Perfil: Prestador de Serviços'
                                  : 'Perfil: Cliente',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Conteúdo Específico por Perfil
              if (isPrestador) ...[
                _buildPrestadorDashboard(context),
              ] else ...[
                _buildClienteDashboard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Dashboard do Cliente
  Widget _buildClienteDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O que você precisa hoje?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CriarSolicitacaoView()),
            );
            if (result == true) {
              _carregarDados();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Solicitar Nova Limpeza',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressView()),
            );
          },
          icon: const Icon(Icons.location_on_outlined),
          label: const Text(
            'Cadastrar Novo Endereço',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),

        // Seção: Prestadores em Destaque na Região
        const Text(
          'Prestadores na Sua Região',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_prestadoresDestaque.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.people_outline, color: Colors.blue),
              title: Text('Nenhum prestador disponível na região ainda.'),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _prestadoresDestaque.length,
              itemBuilder: (context, index) {
                final item = _prestadoresDestaque[index];
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
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['nome'] ?? 'Prestador',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                Text(' ${item['media_nota']}'),
                                if (item['selo_formalizado'] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 14,
                                  ),
                                ],
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

        const SizedBox(height: 24),
        const Text(
          'Minhas Solicitações',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else if (_solicitacoes.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('Nenhuma limpeza solicitada ainda.'),
              subtitle: Text(
                'Toque no botão acima para criar seu primeiro pedido.',
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
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.cleaning_services,
                    color: Colors.blue,
                  ),
                  title: Text(item['nome_categoria'] ?? 'Limpeza'),
                  subtitle: Text(
                    'Data: ${item['data_agendamento']} | Status: ${item['status']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
      ],
    );
  }

  // Dashboard do Prestador
  Widget _buildPrestadorDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão de Formalização MEI / CNPJ
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
          label: const Text(
            'Cadastrar CNPJ / Formalização MEI',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeusServicosView()),
            );
          },
          icon: const Icon(
            Icons.cleaning_services_outlined,
            color: Colors.orange,
          ),
          label: const Text(
            'Gerenciar Meus Serviços & Agenda',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        // Botão do Simulador e Trilha MEI
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrilhaMeiView()),
            );
          },
          icon: const Icon(Icons.school_outlined),
          label: const Text(
            'Conhecer Vantagens & Simulador MEI',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Serviços Disponíveis na Região',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else if (_solicitacoes.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.work_outline, color: Colors.orange),
              title: Text('Nenhum serviço disponível no momento'),
              subtitle: Text(
                'Novas oportunidades de trabalho aparecerão aqui.',
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
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.work, color: Colors.orange),
                  title: Text(item['nome_categoria'] ?? 'Serviço'),
                  subtitle: Text(
                    '${item['bairro'] ?? ""} (${item['cidade'] ?? ""}) - Data: ${item['data_agendamento']}',
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _mostrarDetalhesSolicitacao(item),
                    child: const Text('Ver'),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'Resumo de Atividades',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Concluídos', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'R\$ 0,00',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Ganhos', style: TextStyle(fontSize: 12)),
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
