import 'package:flutter/material.dart';

class ServiceTags extends StatelessWidget {
  const ServiceTags({super.key, required this.tags});

  final List<String> tags;

  static List<String> fromService(Map<String, dynamic> service) {
    final tags = <String>[];
    final seen = <String>{};

    void add(String? value) {
      final label = value?.trim() ?? '';
      if (label.isEmpty || !seen.add(label.toLowerCase())) return;
      tags.add(label);
    }

    final extraTags = service['tags'];
    if (extraTags is Iterable) {
      for (final tag in extraTags) {
        if (tag is String) add(tag);
      }
    }

    add(
      service['nome_categoria']?.toString() ?? service['categoria']?.toString(),
    );

    final modalidade = service['modalidade']?.toString().trim() ?? '';
    if (modalidade.toUpperCase() == 'DOMICILIO') {
      add('Domicílio');
    } else if (modalidade.isNotEmpty) {
      add(_titleCase(modalidade.replaceAll('_', ' ')));
    }

    switch (service['tipo_cobranca']?.toString().toUpperCase()) {
      case 'HORA':
        add('Por hora');
        break;
      case 'TURNO':
        add('Por turno');
        break;
      case 'FIXO':
        add('Preço fixo');
        break;
    }

    return tags;
  }

  static String _titleCase(String value) => value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final tagsValidas = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    if (tagsValidas.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var index = 0; index < tagsValidas.length; index++)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Chip(
              label: Text(
                tagsValidas[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              backgroundColor: index.isEven
                  ? const Color(0xFFEAF2FF)
                  : const Color(0xFFFFF5D6),
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: index.isEven
                    ? const Color(0xFF174A8B)
                    : const Color(0xFF775600),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
