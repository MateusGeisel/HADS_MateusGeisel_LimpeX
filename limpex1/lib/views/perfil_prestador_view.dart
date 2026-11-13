import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/prestador_service.dart';
import 'criar_solicitacao_view.dart';
import 'login_view.dart';
import 'servico_detalhe_view.dart';
import 'components/service_tags.dart';

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
  List<dynamic> _avaliacoes = [];
  bool _carregando = true;
  bool _erroAvaliacoes = false;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final perfilFuture = _prestadorService.buscarPerfilPrestador(
      widget.idPrestador,
    );
    final avaliacoesFuture = _prestadorService.buscarAvaliacoesPrestador(
      widget.idPrestador,
    );
    final dados = await perfilFuture;
    final dadosAvaliacoes = await avaliacoesFuture;
    if (!mounted) return;

    setState(() {
      _perfilData = dados;
      _erroAvaliacoes = dadosAvaliacoes == null;
      _avaliacoes = dadosAvaliacoes?['avaliacoes'] as List<dynamic>? ?? [];
      _carregando = false;
    });
  }

  String _formatarDataAvaliacao(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarValor(dynamic valor) {
    final numero = double.tryParse(
      valor?.toString().replaceAll(',', '.') ?? '',
    );
    if (numero == null) return '—';
    return numero.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarCobranca(dynamic valor) {
    switch (valor?.toString().toUpperCase()) {
      case 'TURNO':
        return 'turno';
      case 'FIXO':
        return 'serviço';
      default:
        return 'hora';
    }
  }

  int _notaDaAvaliacao(dynamic avaliacao) {
    if (avaliacao is! Map) return 0;
    return int.tryParse(avaliacao['nota']?.toString() ?? '') ?? 0;
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return 'C';
    return partes.take(2).map((parte) => parte[0].toUpperCase()).join();
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
    bool agendaDisponivel,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServicoDetalheView(
          servico: servico,
          nomePrestador: nomePrestador,
          agendaDisponivel: agendaDisponivel,
          onSolicitar: () {
            Navigator.pop(context);
            _solicitarServico(servico);
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required String nome,
    required String? imagem,
    required bool formalizado,
    required int totalAvaliacoes,
    required String mediaNota,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 230,
                width: double.infinity,
                child: imagem == null
                    ? _heroImageFallback()
                    : Image.network(
                        imagem,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _heroImageFallback(),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              if (formalizado)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.primaryBlue,
                          size: 17,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Profissional verificado',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROFISSIONAL LIMPEX',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryYellow.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppTheme.prestadorAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalAvaliacoes == 0
                            ? 'Reputação em construção'
                            : 'Avaliação dos clientes',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalAvaliacoes == 0
                            ? 'Ainda sem avaliações'
                            : '$mediaNota de 5  •  $totalAvaliacoes '
                                  '${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (formalizado)
                  const Tooltip(
                    message: 'Dados de formalização verificados',
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF164A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.home_repair_service_outlined,
          color: Colors.white70,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildAvailability(bool disponivel) {
    final cor = disponivel ? const Color(0xFF18794E) : const Color(0xFF9A5B00);
    final fundo = disponivel
        ? const Color(0xFFEAF7EF)
        : const Color(0xFFFFF5E5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              disponivel ? Icons.event_available : Icons.event_busy,
              color: cor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disponivel ? 'Agenda aberta' : 'Agenda fechada',
                  style: TextStyle(
                    color: cor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disponivel
                      ? 'Este profissional está recebendo solicitações.'
                      : 'No momento, não está recebendo novas solicitações.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required Map<String, dynamic> servico,
    required String nomePrestador,
    required bool agendaDisponivel,
  }) {
    final fotos = PrestadorService.extrairFotos(
      servico['fotos'] ??
          servico['foto_url'] ??
          servico['imagem_url'] ??
          servico['imagens'],
    );
    final nome = servico['nome']?.toString() ?? 'Serviço profissional';
    final descricao = servico['descricao']?.toString().trim() ?? '';
    final tags = ServiceTags.fromService(servico);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 168,
            width: double.infinity,
            child: fotos.isEmpty
                ? Container(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.07),
                    child: const Center(
                      child: Icon(
                        Icons.home_repair_service_outlined,
                        color: AppTheme.primaryBlue,
                        size: 46,
                      ),
                    ),
                  )
                : Image.network(
                    fotos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.07),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.textSecondary,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceTags(tags: tags),
                if (tags.isNotEmpty) const SizedBox(height: 10),
                Text(
                  nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao.isEmpty
                      ? 'Consulte os detalhes deste atendimento.'
                      : descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.sell_outlined,
                      color: AppTheme.primaryBlue,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(text: 'A partir de '),
                            TextSpan(
                              text: 'R\$ ${_formatarValor(servico['valor'])}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' / ${_formatarCobranca(servico['tipo_cobranca'])}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: agendaDisponivel
                        ? () => _solicitarServico(servico)
                        : null,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      agendaDisponivel
                          ? 'Solicitar serviço'
                          : 'Agenda indisponível',
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _abrirDetalhesServico(
                      servico,
                      nomePrestador,
                      agendaDisponivel,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver detalhes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection({
    required List<dynamic> servicos,
    required String nomePrestador,
    required bool agendaDisponivel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Serviços disponíveis',
          'Escolha o atendimento ideal e solicite diretamente ao profissional.',
        ),
        const SizedBox(height: 16),
        if (servicos.isEmpty)
          _buildEmptyState(
            icon: Icons.home_repair_service_outlined,
            title: 'Nenhum serviço cadastrado',
            message: 'Este profissional ainda não adicionou serviços específicos ao perfil.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              final colunas = constraints.maxWidth >= 720 ? 2 : 1;
              final largura =
                  (constraints.maxWidth - spacing * (colunas - 1)) / colunas;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in servicos)
                    SizedBox(
                      width: largura,
                      child: _buildServiceCard(
                        servico: Map<String, dynamic>.from(item as Map),
                        nomePrestador: nomePrestador,
                        agendaDisponivel: agendaDisponivel,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final contagens = <int, int>{
      for (var nota = 5; nota >= 1; nota--)
        nota: _avaliacoes
            .where((item) => _notaDaAvaliacao(item) == nota)
            .length,
    };
    final total = _avaliacoes.length;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var nota = 5; nota >= 1; nota--)
              Padding(
                padding: EdgeInsets.only(bottom: nota == 1 ? 0 : 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      child: Text(
                        '$nota',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber, size: 15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: contagens[nota]! / total,
                          minHeight: 7,
                          backgroundColor: AppTheme.backgroundColor,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${contagens[nota]}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> avaliacao) {
    final nome = avaliacao['nome_avaliador']?.toString() ?? 'Cliente';
    final comentario = avaliacao['comentario']?.toString().trim() ?? '';
    final servico = avaliacao['nome_servico']?.toString().trim() ?? '';
    final nota = _notaDaAvaliacao(avaliacao);
    final data = _formatarDataAvaliacao(avaliacao['criado_em']);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.09),
                  child: Text(
                    _iniciais(nome),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (servico.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          servico,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.isNotEmpty)
                  Text(
                    data,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var estrela = 1; estrela <= 5; estrela++)
                  Icon(
                    estrela <= nota ? Icons.star_rounded : Icons.star_outline,
                    size: 19,
                    color: Colors.amber.shade700,
                  ),
                const SizedBox(width: 6),
                Text(
                  '$nota/5',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                comentario,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection({
    required int totalAvaliacoes,
    required String mediaNota,
  }) {
    final media = double.tryParse(mediaNota.replaceAll(',', '.')) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFDCE3EB)),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSectionTitle(
                'Avaliações dos clientes',
                'Experiências de quem já contratou este profissional.',
              ),
            ),
            if (totalAvaliacoes > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryYellow.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.prestadorAccent.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.prestadorAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${media.toStringAsFixed(1)}  •  $totalAvaliacoes',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_erroAvaliacoes)
          _buildEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Avaliações indisponíveis',
            message: 'Não foi possível carregar as avaliações agora.',
          )
        else if (_avaliacoes.isEmpty)
          _buildEmptyState(
            icon: Icons.rate_review_outlined,
            title: 'Ainda sem avaliações',
            message: 'Este prestador ainda não recebeu avaliações de clientes.',
          )
        else ...[
          _buildRatingDistribution(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final colunas = constraints.maxWidth >= 720 ? 2 : 1;
              if (colunas == 1) {
                return Column(
                  children: [
                    for (final item in _avaliacoes) ...[
                      _buildReviewCard(Map<String, dynamic>.from(item as Map)),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              const spacing = 14.0;
              final largura = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in _avaliacoes)
                    SizedBox(
                      width: largura,
                      child: _buildReviewCard(
                        Map<String, dynamic>.from(item as Map),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    final prestador = Map<String, dynamic>.from(
      (_perfilData!['prestador'] ?? _perfilData!) as Map,
    );
    final servicos = (_perfilData!['servicos'] as List<dynamic>?) ?? [];
    final nome = prestador['nome']?.toString() ?? 'Prestador de serviços';
    final formalizado = prestador['selo_formalizado'] == true;
    final agendaDisponivel = prestador['agenda_disponivel'] == true;
    final totalAvaliacoes =
        int.tryParse(prestador['total_avaliacoes']?.toString() ?? '0') ?? 0;
    final mediaNota = prestador['media_nota']?.toString() ?? '0.0';
    final fotosServico = servicos.isEmpty
        ? <String>[]
        : PrestadorService.extrairFotos(
            (servicos.first as Map)['fotos'] ??
                (servicos.first as Map)['foto_url'] ??
                (servicos.first as Map)['imagem_url'] ??
                (servicos.first as Map)['imagens'],
          );
    final fotoPerfil = prestador['foto_perfil']?.toString();
    final imagemHero = fotosServico.isNotEmpty
        ? fotosServico.first
        : (fotoPerfil != null && fotoPerfil.isNotEmpty ? fotoPerfil : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do profissional')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(
                    nome: nome,
                    imagem: imagemHero,
                    formalizado: formalizado,
                    totalAvaliacoes: totalAvaliacoes,
                    mediaNota: mediaNota,
                  ),
                  const SizedBox(height: 16),
                  _buildAvailability(agendaDisponivel),
                  const SizedBox(height: 30),
                  _buildServicesSection(
                    servicos: servicos,
                    nomePrestador: nome,
                    agendaDisponivel: agendaDisponivel,
                  ),
                  const SizedBox(height: 30),
                  _buildReviewsSection(
                    totalAvaliacoes: totalAvaliacoes,
                    mediaNota: mediaNota,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
