import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/views/prestador_navigation_shell.dart';

class _StatefulTab extends StatefulWidget {
  const _StatefulTab();

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Serviços: $_count'),
          ElevatedButton(
            onPressed: () => setState(() => _count++),
            child: const Text('Incrementar'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('mantém o estado das abas ao alternar a navegação', (
    tester,
  ) async {
    Finder navigationLabel(String label) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorNavigationShell(
          dashboard: const Center(child: Text('Conteúdo do dashboard')),
          servicesAndAgenda: const _StatefulTab(),
          profile: const Center(child: Text('Conteúdo do perfil')),
          onRefresh: () {},
          onLogout: () {},
        ),
      ),
    );

    expect(navigationLabel('Dashboard'), findsOneWidget);
    await tester.tap(navigationLabel('Meus Serviços'));
    await tester.pumpAndSettle();
    expect(find.text('Serviços: 0'), findsOneWidget);
    await tester.tap(find.text('Incrementar'));
    await tester.pumpAndSettle();
    expect(find.text('Serviços: 1'), findsOneWidget);

    await tester.tap(navigationLabel('Meu Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo do perfil'), findsOneWidget);

    await tester.tap(navigationLabel('Meus Serviços'));
    await tester.pumpAndSettle();
    expect(find.text('Serviços: 1'), findsOneWidget);
  });
}
