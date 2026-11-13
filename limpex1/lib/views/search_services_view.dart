import 'package:flutter/material.dart';

import '../main.dart';
import '../services/prestador_service.dart';
import 'components/service_tags.dart';
import 'perfil_prestador_view.dart';

class SearchServicesView extends StatefulWidget {
  const SearchServicesView({
    super.key,
    required this.servicos,
    required this.controller,
    required this.carregando,
    required this.onRefresh,
  });

  final List<dynamic> servicos;
  final TextEditingController controller;
  final bool carregando;
  final Future<void> Function() onRefresh;

  @override
  State<SearchServicesView> createState() => _SearchServicesViewState();
}

class _SearchServicesViewState extends State<SearchServicesView> {
  String _termoBusca = '';
  String? _categoriaSelecionada;
  final Set<String> _tagsSelecionadas = {};

  @override
  void initState() {
    super.initState();
    _termoBusca = widget.controller.text;
  }

  @override
  void didUpdateWidget(covariant SearchServicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_termoBusca != widget.controller.text) {
      _termoBusca = widget.controller.text;
    }
  }

  List<Map<String, dynamic>> _servicosOrdenados() {
    final servicos = widget.servicos
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    servicos.sort((a, b) {
      final nota = _numero(b['media_nota']).compareTo(_numero(a['media_nota']));
      if (nota != 0) return nota;

      final avaliacoes = _inteiro(b['total_avaliacoes'])
          .compareTo(_inteiro(a['total_avaliacoes']));
      if (avaliacoes != 0) return avaliacoes;

      final selo = (b['selo_formalizado'] == true ? 1 : 0).compareTo(
        a['selo_formalizado'] == true ? 1 : 0,
      );
      if (selo != 0) return selo;

      return _inteiro(b['id_servico']).compareTo(_inteiro(a['id_servico']));
    });
    return servicos;
  }

  double _numero(dynamic valor) =>
      double.tryParse(valor?.toString() ?? '') ?? 0;

  int _inteiro(dynamic valor) => int.tryParse(valor?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> _filtrarServicos(
    List<Map<String, dynamic>> servicos,
  ) {
    final termo = _termoBusca.trim().toLowerCase();
    return servicos.where((servico) {
      final categoria = (servico['nome_categoria'] ?? '').toString();
      if (_categoriaSelecionada != null &&
          categoria.toLowerCase() != _categoriaSelecionada!.toLowerCase()) {
        return false;
      }

      final tags = ServiceTags.fromService(servico);
      if (!_tagsSelecionadas.every(
        (filtro) =>
            tags.any((tag) => tag.toLowerCase() == filtro.toLowerCase()),
      )) {
        return false;
      }

      if (termo.isEmpty) return true;
      final campos = [
        servico['nome_servico'],
        servico['nome_categoria'],
        servico['descricao_servico'],
        servico['nome'],
        servico['cidade'],
        servico['bairro'],
        ...tags,
      ];
      return campos.any(
        (campo) => campo?.toString().toLowerCase().contains(termo) ?? false,
      );
    }).toList();
  }

  List<String> _categorias(List<Map<String, dynamic>> servicos) =>
      servicos
          .map((servico) => servico['nome_categoria']?.toString().trim() ?? '')
          .where((categoria) => categoria.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  List<String> _tags(List<Map<String, dynamic>> servicos) =>
      servicos.expand(ServiceTags.fromService).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  @override
  Widget build(BuildContext context) {
    final servicos = _servicosOrdenados();
    final categorias = _categorias(servicos);
    final tags = _tags(servicos);
    final resultados = _filtrarServicos(servicos);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: widget.controller,
                textInputAction: TextInputAction.search,
                onChanged: (valor) => setState(() => _termoBusca = valor),
                decoration: InputDecoration(
                  hintText: 'Buscar serviço, categoria ou profissional',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: widget.controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            widget.controller.clear();
                            setState(() => _termoBusca = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (categorias.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildChoiceFilters(
                title: 'Categorias',
                options: categorias,
                selected: _categoriaSelecionada,
                onSelected: (value) =>
                    setState(() => _categoriaSelecionada = value),
              ),
            ),
          if (tags.isNotEmpty)
            SliverToBoxAdapter(child: _buildTagFilters(tags)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${resultados.length} ${resultados.length == 1 ? 'serviço encontrado' : 'serviços encontrados'}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.carregando && servicos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (resultados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    servicos.isEmpty ? 'Ainda não há serviços disponíveis.' : 'Nenhum serviço corresponde aos filtros selecionados.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SearchServiceCard(
                      key: ValueKey(resultados[index]['id_servico']),
                      servico: resultados[index],
                    ),
                  ),
                  childCount: resultados.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceFilters({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                ),
                const SizedBox(width: 8),
                for (final option in options) ...[
                  ChoiceChip(
                    label: Text(option),
                    selected: selected == option,
                    onSelected: (_) =>
                        onSelected(selected == option ? null : option),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilters(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in tags)
                FilterChip(
                  label: Text(tag),
                  selected: _tagsSelecionadas.contains(tag),
                  onSelected: (selecionada) {
                    setState(() {
                      if (selecionada) {
                        _tagsSelecionadas.add(tag);
                      } else {
                        _tagsSelecionadas.remove(tag);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchServiceCard extends StatefulWidget {
  const _SearchServiceCard({super.key, required this.servico});

  final Map<String, dynamic> servico;

  @override
  State<_SearchServiceCard> createState() => _SearchServiceCardState();
}

class _SearchServiceCardState extends State<_SearchServiceCard> {
  int _paginaAtual = 0;

  @override
  Widget build(BuildContext context) {
    final servico = widget.servico;
    final fotos = PrestadorService.extrairFotos(
      servico['fotos_servicos'] ?? servico['fotos'],
    );
    final nome = servico['nome_servico']?.toString() ?? 'Serviço';
    final nomePrestador = servico['nome']?.toString() ?? 'Profissional';
    final idPrestador = int.tryParse(servico['id_prestador']?.toString() ?? '');
    final nota = double.tryParse(servico['media_nota']?.toString() ?? '') ?? 0;
    final totalAvaliacoes =
        int.tryParse(servico['total_avaliacoes']?.toString() ?? '') ?? 0;
    final cobranca = switch (servico['tipo_cobranca']?.toString()) {
      'TURNO' => 'por turno',
      'FIXO' => 'por serviço',
      _ => 'por hora',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: idPrestador == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilPrestadorView(idPrestador: idPrestador),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fotos.isEmpty)
                    _buildImagemIndisponivel()
                  else
                    PageView.builder(
                      itemCount: fotos.length,
                      onPageChanged: (pagina) =>
                          setState(() => _paginaAtual = pagina),
                      itemBuilder: (context, index) => Image.network(
                        fotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildImagemIndisponivel(),
                      ),
                    ),
                  if (fotos.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0; index < fotos.length; index++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: index == _paginaAtual ? 16 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == _paginaAtual
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceTags(tags: ServiceTags.fromService(servico)),
                  const SizedBox(height: 8),
                  Text(
                    nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Oferecido por $nomePrestador',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((servico['descricao_servico'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      servico['descricao_servico'].toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          totalAvaliacoes == 0
                              ? 'Novo'
                              : '${nota.toStringAsFixed(1)} ($totalAvaliacoes avaliações)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'R\$ ${servico['valor'] ?? '—'} $cobranca',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((servico['bairro'] ?? servico['cidade']) != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                            servico['bairro']?.toString(),
                            servico['cidade']?.toString(),
                          ]
                          .where((parte) => parte != null && parte.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagemIndisponivel() {
    return Container(
      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.home_repair_service_outlined,
        size: 48,
        color: AppTheme.primaryBlue,
      ),
    );
  }
}
