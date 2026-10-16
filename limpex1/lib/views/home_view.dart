import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/solicitacao_service.dart';
import 'login_view.dart';
import 'add_address_view.dart';
import 'prestador_formalizacao_view.dart';
import 'trilha_mei_view.dart';
import 'criar_solicitacao_view.dart';

class HomeView extends StatefulWidget {
  final UserModel user;

  const HomeView({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  List<dynamic> _solicitacoes = [];
  bool _carregandoSolicitacoes = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.tipoPerfil != 'PRESTADOR') {
      _carregarSolicitacoes();
    }
  }

  Future<void> _carregarSolicitacoes() async {
    setState(() => _carregandoSolicitacoes = true);
    final lista = await _solicitacaoService.buscarMinhasSolicitacoes();
    setState(() {
      _solicitacoes = lista;
      _carregandoSolicitacoes = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final bool isPrestador = widget.user.tipoPerfil == 'PRESTADOR';

    return Scaffold(
      appBar: AppBar(
        title: Text('LimpeX - ${isPrestador ? "Painel do Prestador" : "Início"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _fazerLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Boas-Vindas
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isPrestador ? Colors.orange : Colors.blue,
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
                          Text(
                            'Olá, ${widget.user.nome}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CriarSolicitacaoView()),
            );
            if (result == true) {
              _carregarSolicitacoes();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Solicitar Nova Limpeza', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressView()),
            );
          },
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Cadastrar Novo Endereço', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Minhas Solicitações',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_carregandoSolicitacoes)
          const Center(child: CircularProgressIndicator())
        else if (_solicitacoes.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('Nenhuma limpeza solicitada ainda.'),
              subtitle: Text('Toque no botão acima para criar seu primeiro pedido.'),
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
                  leading: const Icon(Icons.cleaning_services, color: Colors.blue),
                  title: Text(item['nome_categoria'] ?? 'Limpeza'),
                  subtitle: Text(
                    'Data: ${item['data_agendamento']} - Status: ${item['status']}',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrestadorFormalizacaoView()),
            );
          },
          icon: const Icon(Icons.verified),
          label: const Text('Cadastrar CNPJ / Formalização MEI', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        // Botão do Simulador e Trilha MEI
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrilhaMeiView()),
            );
          },
          icon: const Icon(Icons.school_outlined),
          label: const Text('Conhecer Vantagens & Simulador MEI', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Serviços Disponíveis na Região',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.work_outline, color: Colors.orange),
            title: Text('Nenhum serviço disponível no momento'),
            subtitle: Text('Novas oportunidades de trabalho aparecerão aqui.'),
          ),
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
                      Text('0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                      Text('R\$ 0,00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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