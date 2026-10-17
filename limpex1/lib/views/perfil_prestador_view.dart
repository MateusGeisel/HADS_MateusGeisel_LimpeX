import 'package:flutter/material.dart';
import '../services/prestador_service.dart';
import 'criar_solicitacao_view.dart';

class PerfilPrestadorView extends StatefulWidget {
  final int idPrestador;

  const PerfilPrestadorView({Key? key, required this.idPrestador}) : super(key: key);

  @override
  State<PerfilPrestadorView> createState() => _PerfilPrestadorViewState();
}

class _PerfilPrestadorViewState extends State<PerfilPrestadorView> {
  final PrestadorService _prestadorService = PrestadorService();
  Map<String, dynamic>? _perfil;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final dados = await _prestadorService.buscarPerfilPrestador(widget.idPrestador);
    setState(() {
      _perfil = dados;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Prestador')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfil == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Prestador')),
        body: const Center(child: Text('Não foi possível carregar o perfil.')),
      );
    }

    final servicos = _perfil!['servicos'] as List<dynamic>? ?? [];
    final bool temSelo = _perfil!['selo_formalizado'] == true;
    final bool isMei = _perfil!['optante_mei'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(_perfil!['nome'] ?? 'Perfil do Prestador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Perfil
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.person, size: 40, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _perfil!['nome'] ?? 'Prestador',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (temSelo)
                                const Tooltip(
                                  message: 'Prestador Verificado & Formalizado',
                                  child: Icon(Icons.verified, color: Colors.blue, size: 22),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _perfil!['cidade'] != null
                                ? '${_perfil!['bairro'] ?? ""}, ${_perfil!['cidade']}'
                                : 'Localização não informada',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${_perfil!['media_nota']} (${_perfil!['total_avaliacoes']} avaliações)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Badge MEI / Formalização
            if (isMei || temSelo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMei
                            ? 'Prestador Formalizado (MEI/CNPJ Ativo)'
                            : 'Perfil Verificado pela Plataforma',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              'Serviços Ofertados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (servicos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Este prestador ainda não cadastrou serviços específicos.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: servicos.length,
                itemBuilder: (context, index) {
                  final item = servicos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['nome'] ?? 'Serviço',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'R\$ ${item['valor']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (item['descricao'] != null && item['descricao'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(item['descricao'], style: TextStyle(color: Colors.grey[700])),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Solicitar Este Serviço'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CriarSolicitacaoView(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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