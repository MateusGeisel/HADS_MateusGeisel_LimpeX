import 'package:flutter/material.dart';

import '../services/prestador_service.dart';
import '../main.dart';

class PerfilPrestadorView extends StatefulWidget {
  final int idPrestador;

  const PerfilPrestadorView({super.key, required this.idPrestador});

  @override
  State<PerfilPrestadorView> createState() => _PerfilPrestadorViewState();
}

class _PerfilPrestadorViewState extends State<PerfilPrestadorView> {
  final PrestadorService _prestadorService = PrestadorService();
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

    final prestador = _perfilData!['prestador'] ?? {};
    final List<dynamic> servicos = _perfilData!['servicos'] ?? [];
    final bool isFormalizado = prestador['selo_formalizado'] == true;

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
                  final List<dynamic> fotos = item['fotos'] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  'R\$ ${item['valor']} / ${item['tipo_cobranca'] == "TURNO" ? "Turno" : "Hora"}',
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
                          if (fotos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 75,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length,
                                itemBuilder: (context, fIndex) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 75,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(fotos[fIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Solicitar Este Serviço'),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Serviço "${item['nome']}" selecionado!',
                                    ),
                                    backgroundColor: Colors.green,
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
