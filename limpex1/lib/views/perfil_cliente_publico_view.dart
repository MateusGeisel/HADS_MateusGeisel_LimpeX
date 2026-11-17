import 'package:flutter/material.dart';

import '../main.dart';
import '../services/profile_service.dart';

class PerfilClientePublicoView extends StatefulWidget {
  const PerfilClientePublicoView({super.key, required this.idCliente});

  final int idCliente;

  @override
  State<PerfilClientePublicoView> createState() =>
      _PerfilClientePublicoViewState();
}

class _PerfilClientePublicoViewState extends State<PerfilClientePublicoView> {
  final ProfileService _profileService = ProfileService();
  late Future<Map<String, dynamic>> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _profileService.buscarPerfilPublicoCliente(widget.idCliente);
  }

  void _recarregar() {
    setState(() {
      _perfil = _profileService.buscarPerfilPublicoCliente(widget.idCliente);
    });
  }

  String _formatarData(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '')?.toLocal();
    if (data == null) return 'Data de cadastro não disponível';
    return 'Na plataforma desde ${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Widget _fotoCliente(String? url, {double tamanho = 76}) {
    final foto = url?.trim();
    return CircleAvatar(
      radius: tamanho / 2,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      child: ClipOval(
        child: foto == null || foto.isEmpty
            ? Icon(
                Icons.person_outline,
                color: AppTheme.primaryBlue,
                size: tamanho * 0.55,
              )
            : Image.network(
                foto,
                width: tamanho,
                height: tamanho,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryBlue,
                  size: tamanho * 0.55,
                ),
              ),
      ),
    );
  }

  Widget _estrelas(double media) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var estrela = 1; estrela <= 5; estrela++)
        Icon(
          media >= estrela
              ? Icons.star
              : media >= estrela - 0.5
              ? Icons.star_half
              : Icons.star_border,
          color: Colors.amber.shade700,
          size: 20,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do cliente')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfil,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível carregar o perfil do cliente.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final perfil = snapshot.data!;
          final nome = perfil['nome']?.toString() ?? 'Cliente LimpeX';
          final media =
              double.tryParse(perfil['media_avaliacoes']?.toString() ?? '') ??
              0;
          final totalAvaliacoes =
              int.tryParse(perfil['total_avaliacoes']?.toString() ?? '') ?? 0;
          final totalSolicitacoes =
              int.tryParse(perfil['total_solicitacoes']?.toString() ?? '') ?? 0;
          final avaliacoes = (perfil['avaliacoes'] is List)
              ? (perfil['avaliacoes'] as List)
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList()
              : <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _fotoCliente(perfil['foto_perfil']?.toString()),
                      const SizedBox(height: 12),
                      Text(
                        nome,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatarData(perfil['cadastrado_em']),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _estrelas(media),
                      const SizedBox(height: 4),
                      Text(
                        totalAvaliacoes == 0
                            ? 'Ainda sem avaliações'
                            : '${media.toStringAsFixed(1)} de 5 · '
                                  '$totalAvaliacoes '
                                  '${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalSolicitacoes '
                        '${totalSolicitacoes == 1 ? 'serviço solicitado' : 'serviços solicitados'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Avaliações dos prestadores',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (avaliacoes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Este cliente ainda não recebeu avaliações.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                for (final avaliacao in avaliacoes) _buildAvaliacao(avaliacao),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvaliacao(Map<String, dynamic> avaliacao) {
    final nota = int.tryParse(avaliacao['nota']?.toString() ?? '') ?? 0;
    final comentario = avaliacao['comentario']?.toString().trim() ?? '';
    final data = DateTime.tryParse(avaliacao['criado_em']?.toString() ?? '')
        ?.toLocal();
    final dataFormatada = data == null
        ? ''
        : '${data.day.toString().padLeft(2, '0')}/'
              '${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    avaliacao['nome_prestador']?.toString() ??
                        'Prestador LimpeX',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (dataFormatada.isNotEmpty)
                  Text(
                    dataFormatada,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _estrelas(nota.toDouble()),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comentario),
            ],
          ],
        ),
      ),
    );
  }
}
