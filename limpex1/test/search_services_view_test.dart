import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/views/search_services_view.dart';

void main() {
  const servicos = [
    {
      'id_servico': 1,
      'nome_servico': 'Pintura residencial',
      'nome_categoria': 'Pintura',
      'nome': 'Ana',
      'media_nota': 4.8,
      'total_avaliacoes': 12,
      'fotos_servicos': [],
      'valor': 100,
      'tipo_cobranca': 'FIXO',
    },
    {
      'id_servico': 2,
      'nome_servico': 'Limpeza completa',
      'nome_categoria': 'Limpeza',
      'nome': 'Bia',
      'media_nota': 5.0,
      'total_avaliacoes': 3,
      'fotos_servicos': [],
      'valor': 80,
      'tipo_cobranca': 'FIXO',
    },
  ];

  Future<void> pumpSearch(WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchServicesView(
            servicos: servicos,
            controller: controller,
            carregando: false,
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ordena serviços por avaliação e filtra por categoria', (
    tester,
  ) async {
    await pumpSearch(tester);

    expect(find.text('Limpeza completa'), findsOneWidget);
    expect(find.text('Pintura residencial'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Pintura residencial'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pintura residencial'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pintura'));
    await tester.pumpAndSettle();

    expect(find.text('1 serviço encontrado'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pintura residencial'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pintura residencial'), findsOneWidget);
    expect(find.text('Limpeza completa'), findsNothing);
  });

  testWidgets('serviço com várias fotos permite deslizar a galeria', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchServicesView(
            servicos: [
              {
                ...servicos.first,
                'fotos_servicos': [
                  'https://example.com/foto-1.jpg',
                  'https://example.com/foto-2.jpg',
                ],
              },
            ],
            controller: controller,
            carregando: false,
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    final indicadores = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect(indicadores, hasLength(2));
    expect(tester.getSize(find.byType(AnimatedContainer).first).width, 22);
    expect(tester.getSize(find.byType(AnimatedContainer).last).width, 14);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();

    final indicadoresAtualizados = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(indicadoresAtualizados, hasLength(2));
    expect(tester.getSize(find.byType(AnimatedContainer).first).width, 14);
    expect(tester.getSize(find.byType(AnimatedContainer).last).width, 22);
  });
}
