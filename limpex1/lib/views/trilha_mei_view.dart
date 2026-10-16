import 'package:flutter/material.dart';
import '../services/prestador_service.dart';

class TrilhaMeiView extends StatefulWidget {
  const TrilhaMeiView({Key? key}) : super(key: key);

  @override
  State<TrilhaMeiView> createState() => _TrilhaMeiViewState();
}

class _TrilhaMeiViewState extends State<TrilhaMeiView> {
  final _prestadorService = PrestadorService();

  double _faturamentoEstimado = 3000.0;
  final double _valorDasFixo = 75.00; // Valor aproximado da guia mensal MEI (INSS + ISS)

  @override
  void initState() {
    super.initState();
    _prestadorService.registrarProgressoTrilha('LEITURA_GUIA');
  }

  void _simular() {
    _prestadorService.registrarProgressoTrilha('SIMULACAO_CUSTO');
  }

  @override
  Widget build(BuildContext context) {
    final double inssAposentadoria = _valorDasFixo * 0.95;
    final double faturamentoAnual = _faturamentoEstimado * 12;

    return Scaffold(
      appBar: AppBar(title: const Text('Trilha & Simulador MEI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Destaque
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 40, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Seja um Prestador Formalizado no LimpeX!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Simulador Financeiro MEI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Arraste o slider para estimar seu faturamento mensal e ver a proporção do custo fixo:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Slider de Faturamento
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Faturamento Mensal Estimado: R\$ ${_faturamentoEstimado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Slider(
                      value: _faturamentoEstimado,
                      min: 1000.0,
                      max: 6750.0, // Limite mensal proporcional MEI (81k/ano)
                      divisions: 23,
                      label: 'R\$ ${_faturamentoEstimado.round()}',
                      onChanged: (value) {
                        setState(() {
                          _faturamentoEstimado = value;
                        });
                        _simular();
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Guia Mensal DAS (Fixo):'),
                        Text(
                          'R\$ ${_valorDasFixo.toStringAsFixed(2)} / mês',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Faturamento Anual Projetado:'),
                        Text(
                          'R\$ ${faturamentoAnual.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Vantagens do MEI para você:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const ListTile(
              leading: Icon(Icons.shield, color: Colors.green),
              title: Text('Proteção Previdenciária'),
              subtitle: Text('Auxílio-doença, aposentadoria por idade e licença-maternidade.'),
            ),
            const ListTile(
              leading: Icon(Icons.receipt_long, color: Colors.blue),
              title: Text('Emissão de Notas Fiscais'),
              subtitle: Text('Atenda empresas e condomínios que exigem NFS-e.'),
            ),
            const ListTile(
              leading: Icon(Icons.verified, color: Colors.orange),
              title: Text('Selo de Formalizado no LimpeX'),
              subtitle: Text('Perfil destacado na busca com maior prioridade de chamados.'),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _prestadorService.registrarProgressoTrilha('REDIRECIONADO_PORTAL');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abra o Portal do Empreendedor no seu navegador (gov.br/mei)'),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir Portal do Empreendedor (GOV.BR)', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}