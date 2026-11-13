import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/models/address_model.dart';
import 'package:limpex1/models/user_model.dart';
import 'package:limpex1/services/address_service.dart';
import 'package:limpex1/services/profile_service.dart';
import 'package:limpex1/views/client_profile_view.dart';

class _FakeProfileService extends ProfileService {
  String? savedName;

  @override
  Future<Map<String, dynamic>> getProfile() async => {
    'nome': 'Camila Cliente',
    'email': 'camila@example.com',
    'telefone': '11999990000',
    'foto_perfil': null,
  };

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String nome,
    required String telefone,
    String? fotoPerfil,
  }) async {
    savedName = nome;
    return {
      'nome': nome,
      'email': 'camila@example.com',
      'telefone': telefone,
      'foto_perfil': fotoPerfil,
    };
  }
}

class _FakeAddressService extends AddressService {
  @override
  Future<List<AddressModel>> getAddresses() async => [];
}

void main() {
  testWidgets('separa perfil e serviços por status', (tester) async {
    final profileService = _FakeProfileService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientProfileView(
            user: UserModel(
              id: 1,
              nome: 'Camila Cliente',
              email: 'camila@example.com',
            ),
            solicitacoes: const [
              {
                'id_solicitacao': 1,
                'status': 'PENDENTE',
                'nome_servico': 'Montador de Móveis',
                'data_agendamento': '2026-12-01',
              },
              {
                'id_solicitacao': 2,
                'status': 'EM_ANDAMENTO',
                'nome_servico': 'Pintura Residencial',
                'data_agendamento': '2026-12-02',
              },
              {
                'id_solicitacao': 3,
                'status': 'CONCLUIDO',
                'nome_servico': 'Limpeza Completa',
                'data_agendamento': '2026-11-01',
                'avaliada': true,
              },
            ],
            carregandoSolicitacoes: false,
            onRefreshSolicitacoes: () async {},
            podeCancelarSolicitacao: (_) => false,
            onCancelarSolicitacao: (_) async {},
            onAvaliarSolicitacao: (_) async {},
            profileService: profileService,
            addressService: _FakeAddressService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados pessoais'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Camila Atualizada',
    );
    await tester.ensureVisible(find.text('Salvar perfil'));
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();
    expect(profileService.savedName, 'Camila Atualizada');

    await tester.tap(find.text('Meus Serviços'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitações em aberto'), findsOneWidget);
    expect(find.text('Montador de Móveis'), findsOneWidget);
    expect(find.text('Serviços em andamento'), findsOneWidget);
    expect(find.text('Pintura Residencial'), findsOneWidget);
    expect(find.text('Serviços concluídos'), findsOneWidget);
    expect(find.text('Limpeza Completa'), findsOneWidget);
  });
}
