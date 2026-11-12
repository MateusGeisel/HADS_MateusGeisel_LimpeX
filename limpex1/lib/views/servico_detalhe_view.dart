import 'package:flutter/material.dart';

import '../main.dart';
import '../services/prestador_service.dart';

class ServicoDetalheView extends StatefulWidget {
  final Map<String, dynamic> servico;
  final String nomePrestador;
  final VoidCallback onSolicitar;
  final bool agendaDisponivel;

  const ServicoDetalheView({
    super.key,
    required this.servico,
    required this.nomePrestador,
    required this.onSolicitar,
    required this.agendaDisponivel,
  });

  @override
  State<ServicoDetalheView> createState() => _ServicoDetalheViewState();
}

class _ServicoDetalheViewState extends State<ServicoDetalheView> {
  int _paginaAtual = 0;

  @override
  Widget build(BuildContext context) {
    final servico = widget.servico;
    final fotos = PrestadorService.extrairFotos(
      servico['fotos'] ??
          servico['foto_url'] ??
          servico['imagem_url'] ??
          servico['imagens'],
    );
    final cobranca = switch (servico['tipo_cobranca']) {
      'TURNO' => 'Turno',
      'FIXO' => 'Fixo',
      _ => 'Hora',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do serviço')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 300,
            child: fotos.isEmpty
                ? Container(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 56,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text('Este serviço ainda não tem fotos'),
                      ],
                    ),
                  )
                : PageView.builder(
                    itemCount: fotos.length,
                    onPageChanged: (pagina) {
                      setState(() => _paginaAtual = pagina);
                    },
                    itemBuilder: (context, index) => Image.network(
                      fotos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 48),
                            SizedBox(height: 8),
                            Text('Não foi possível carregar esta foto'),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (fotos.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  fotos.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _paginaAtual
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico['nome']?.toString() ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Oferecido por ${widget.nomePrestador}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'R\$ ${servico['valor'] ?? '—'} / $cobranca',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Sobre este serviço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  servico['descricao']?.toString().trim().isNotEmpty == true
                      ? servico['descricao'].toString()
                      : 'O prestador não informou uma descrição.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: widget.agendaDisponivel ? widget.onSolicitar : null,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(
              widget.agendaDisponivel
                  ? 'Solicitar este serviço'
                  : 'Agenda fechada no momento',
            ),
          ),
        ),
      ),
    );
  }
}
