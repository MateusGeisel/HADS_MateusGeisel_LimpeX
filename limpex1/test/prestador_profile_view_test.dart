import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/models/address_model.dart';
import 'package:limpex1/models/user_model.dart';
import 'package:limpex1/services/address_service.dart';
import 'package:limpex1/services/prestador_service.dart';
import 'package:limpex1/views/prestador_profile_view.dart';

class _FakePrestadorService extends PrestadorService {
  @override
  Future<Map<String, dynamic>> buscarMeuPerfil() async => {
    'nome': 'Ana Prestadora',
    'email': 'ana@example.com',
    'telefone': '11999999999',
    'foto_perfil': null,
    'biografia': 'Atendimento profissional para sua casa.',
    'selo_formalizado': false,
    'optante_mei': false,
  };
}

class _FakeAddressService extends AddressService {
  @override
  Future<List<AddressModel>> getAddresses() async => [];
}

void main() {
  testWidgets('exibe as configurações e a seção de formalização', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrestadorProfileView(
            user: UserModel(
              id: 1,
              nome: 'Ana Prestadora',
              email: 'ana@example.com',
              tipoPerfil: 'PRESTADOR',
            ),
            prestadorService: _FakePrestadorService(),
            addressService: _FakeAddressService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurações do perfil'), findsOneWidget);
    expect(
      find.text('Atendimento profissional para sua casa.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();

    expect(find.text('Meu Negócio / MEI'), findsOneWidget);
    expect(find.text('Cadastrar CNPJ / Formalização'), findsOneWidget);
    expect(find.text('Vantagens do MEI e Simulador'), findsOneWidget);
  });
}
