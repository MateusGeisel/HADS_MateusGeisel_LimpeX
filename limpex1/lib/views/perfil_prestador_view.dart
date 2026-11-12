import 'package:flutter/material.dart';

import '../services/prestador_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'login_view.dart';
import 'criar_solicitacao_view.dart';
import 'servico_detalhe_view.dart';

class PerfilPrestadorView extends StatefulWidget {
  final int idPrestador;

  const PerfilPrestadorView({super.key, required this.idPrestador});

  @override
  State<PerfilPrestadorView> createState() => _PerfilPrestadorViewState();
}

class _PerfilPrestadorViewState extends State<PerfilPrestadorView> {
  final PrestadorService _prestadorService = PrestadorService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _perfilData;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final dados = await _prestadorService.buscarPerfilPrestador(
      widget.idPrestador,
    );
    if (mounted) {
      setState(() {
        _perfilData = dados;
        _carregando = false;
      });
    }
  }

  Future<void> _solicitarServico(Map<String, dynamic> servico) async {
    final token = await _authService.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      final desejaEntrar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Entre para contratar'),
          content: const Text(
            'Você pode explorar os perfis livremente. Para solicitar um serviço, entre ou crie sua conta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );

      if (desejaEntrar == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CriarSolicitacaoView(servico: servico)),
    );
  }

  void _abrirDetalhesServico(
    Map<String, dynamic> servico,
    String nomePrestador,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServicoDetalheView(
          servico: servico,
          nomePrestador: nomePrestador,
          agendaDisponivel: _perfilData?['agenda_disponivel'] == true,
          onSolicitar: () {
            Navigator.pop(context);
            _solicitarServico(servico);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Prestador')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfilData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Prestador')),
        body: const Center(child: Text('Não foi possível carregar o perfil.')),
      );
    }

    final prestador = _perfilData!['prestador'] ?? _perfilData!;
    final List<dynamic> servicos = _perfilData!['servicos'] ?? [];
    final bool isFormalizado = prestador['selo_formalizado'] == true;
    final bool agendaDisponivel = prestador['agenda_disponivel'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(prestador['nome'] ?? 'Perfil do Prestador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Principal do Prestador
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.secondaryYellow.withValues(
                            alpha: 0.2,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 48,
                            color: AppTheme.prestadorAccent,
                          ),
                        ),
                        if (isFormalizado)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.verified,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      prestador['nome'] ?? 'Prestador de Serviços',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(
                          ' ${prestador['media_nota'] ?? "5.0"} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          '(Avaliações recentes)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (isFormalizado) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppTheme.primaryBlue,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Prestador Formalizado (MEI / CNPJ)',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
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
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: agendaDisponivel
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    agendaDisponivel ? Icons.event_available : Icons.event_busy,
                    color: agendaDisponivel ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      agendaDisponivel
                          ? 'Este prestador está recebendo solicitações.'
                          : 'Este prestador não está recebendo solicitações no momento.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Serviços Ofertados por Este Profissional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (servicos.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este prestador ainda não cadastrou serviços específicos.',
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
                itemCount: servicos.length,
                itemBuilder: (context, index) {
                  final item = servicos[index];
                  final fotos = PrestadorService.extrairFotos(
                    item['fotos'] ??
                        item['foto_url'] ??
                        item['imagem_url'] ??
                        item['imagens'],
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _abrirDetalhesServico(
                        Map<String, dynamic>.from(item),
                        prestador['nome']?.toString() ?? 'Prestador',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fotos.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  fotos.first,
                                  width: double.infinity,
                                  height: 170,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const SizedBox(
                                      height: 170,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 170,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'R\$ ${item['valor']} / ${item['tipo_cobranca'] == "TURNO"
                                        ? "Turno"
                                        : item['tipo_cobranca'] == "FIXO"
                                        ? "Fixo"
                                        : "Hora"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (item['descricao'] != null &&
                                item['descricao'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item['descricao'],
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Ver detalhes',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
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
