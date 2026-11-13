import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/views/components/service_tags.dart';

void main() {
  test('builds unique category, modality, billing and custom tags', () {
    final tags = ServiceTags.fromService({
      'nome_categoria': 'Pintura',
      'modalidade': 'DOMICILIO',
      'tipo_cobranca': 'TURNO',
      'tags': ['Pintura', 'Interno'],
    });

    expect(tags, ['Pintura', 'Interno', 'Domicílio', 'Por turno']);
  });

  testWidgets('wraps four tags within a narrow card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: ServiceTags(
                tags: ['Pintura', 'Domicílio', 'Por hora', 'Interno'],
              ),
            ),
          ),
        ),
      ),
    );

    final chips = find.byType(Chip);
    expect(chips, findsNWidgets(4));
    expect(tester.takeException(), isNull);
    final wrapBounds = tester.getRect(find.byType(Wrap));
    final chipRects = [
      for (var index = 0; index < 4; index++) tester.getRect(chips.at(index)),
    ];
    expect(wrapBounds.width, lessThanOrEqualTo(140));
    expect(chipRects.map((rect) => rect.top).toSet().length, greaterThan(1));
    expect(
      chipRects.every(
        (rect) =>
            rect.left >= wrapBounds.left && rect.right <= wrapBounds.right,
      ),
      isTrue,
    );
  });
}
