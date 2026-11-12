import 'package:flutter/material.dart';

import '../services/solicitacao_service.dart';

class AvaliarServicoView extends StatefulWidget {
  final int idSolicitacao;
  final String nomePrestador;

  const AvaliarServicoView({
    super.key,
    required this.idSolicitacao,
    required this.nomePrestador,
  });

  @override
  State<AvaliarServicoView> createState() => _AvaliarServicoViewState();
}

class _AvaliarServicoViewState extends State<AvaliarServicoView> {
  final SolicitacaoService _solicitacaoService = SolicitacaoService();
  final TextEditingController _comentarioController = TextEditingController();
  int _nota = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarAvaliacao() async {
    if (_nota == 0 || _enviando) return;
    setState(() => _enviando = true);

    final sucesso = await _solicitacaoService.avaliarSolicitacao(
      idSolicitacao: widget.idSolicitacao,
      nota: _nota,
      comentario: _comentarioController.text.trim(),
    );
    if (!mounted) return;

    setState(() => _enviando = false);
    if (sucesso) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível registrar a avaliação. Tente novamente.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliar serviço')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Como foi o atendimento de ${widget.nomePrestador}?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sua avaliação ajuda outros clientes a escolher um profissional.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  tooltip:
                      '${index + 1} ${index == 0 ? 'estrela' : 'estrelas'}',
                  onPressed: _enviando
                      ? null
                      : () => setState(() => _nota = index + 1),
                  iconSize: 42,
                  color: Colors.amber.shade700,
                  icon: Icon(index < _nota ? Icons.star : Icons.star_border),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              _nota == 0 ? 'Selecione uma nota' : '$_nota de 5 estrelas',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _comentarioController,
            enabled: !_enviando,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Comentário (opcional)',
              hintText: 'Conte como foi sua experiência com o serviço.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _nota == 0 || _enviando ? null : _enviarAvaliacao,
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_enviando ? 'Enviando...' : 'Enviar avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}
