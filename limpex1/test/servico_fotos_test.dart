import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/services/prestador_service.dart';
import 'package:limpex1/views/servico_detalhe_view.dart';

void main() {
  group('PrestadorService.extrairFotos', () {
    test('aceita lista de URLs', () {
      expect(
        PrestadorService.extrairFotos(['https://storage.example.com/foto.jpg']),
        ['https://storage.example.com/foto.jpg'],
      );
    });

    test('decodifica lista JSON e array do PostgreSQL', () {
      expect(
        PrestadorService.extrairFotos(
          '["https://storage.example.com/foto.jpg"]',
        ),
        ['https://storage.example.com/foto.jpg'],
      );
      expect(
        PrestadorService.extrairFotos('{https://storage.example.com/foto.jpg}'),
        ['https://storage.example.com/foto.jpg'],
      );
    });

    test('ignora valores que não sejam URLs http(s)', () {
      expect(
        PrestadorService.extrairFotos(['not-a-url', 'file:///foto.jpg']),
        isEmpty,
      );
    });
  });

  group('PrestadorService.fotosParaExibicao', () {
    test('coloca a foto de perfil antes das fotos originais do serviço', () {
      expect(
        PrestadorService.fotosParaExibicao(
          fotoPerfil: ' https://storage.example.com/perfil.jpg ',
          fotosServico: [
            'https://storage.example.com/servico-1.jpg',
            'https://storage.example.com/servico-2.jpg',
          ],
        ),
        [
          'https://storage.example.com/perfil.jpg',
          'https://storage.example.com/servico-1.jpg',
          'https://storage.example.com/servico-2.jpg',
        ],
      );
    });

    test(
      'usa fotos do serviço se a foto de perfil estiver ausente ou inválida',
      () {
        const fotosServico = ['https://storage.example.com/servico.jpg'];
        expect(
          PrestadorService.fotosParaExibicao(
            fotoPerfil: ' ',
            fotosServico: fotosServico,
          ),
          fotosServico,
        );
        expect(
          PrestadorService.fotosParaExibicao(
            fotoPerfil: 'not-a-url',
            fotosServico: fotosServico,
          ),
          fotosServico,
        );
        expect(
          PrestadorService.fotosParaExibicao(
            fotoPerfil: null,
            fotosServico: null,
          ),
          isEmpty,
        );
      },
    );
  });

  testWidgets('detalhes exibem a foto de perfil primeiro na galeria', (
    tester,
  ) async {
    const fotoPerfil = 'https://storage.example.com/perfil.jpg';
    await tester.pumpWidget(
      MaterialApp(
        home: ServicoDetalheView(
          servico: {
            'foto_perfil': fotoPerfil,
            'fotos': [
              'https://storage.example.com/servico-1.jpg',
              'https://storage.example.com/servico-2.jpg',
            ],
          },
          nomePrestador: 'Ana',
          onSolicitar: () {},
          agendaDisponivel: true,
        ),
      ),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(
      (pageView.childrenDelegate as SliverChildBuilderDelegate).childCount,
      3,
    );
    final primeiraImagem = tester.widget<Image>(
      find
          .descendant(of: find.byType(PageView), matching: find.byType(Image))
          .first,
    );
    expect(
      primeiraImagem.image,
      isA<NetworkImage>().having((image) => image.url, 'url', fotoPerfil),
    );
  });

  testWidgets('detalhes exibem placeholder sem URLs válidas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServicoDetalheView(
          servico: {
            'foto_perfil': ' ',
            'fotos': ['', null],
          },
          nomePrestador: 'Ana',
          onSolicitar: () {},
          agendaDisponivel: true,
        ),
      ),
    );

    expect(find.byType(PageView), findsNothing);
    expect(find.text('Este serviço ainda não tem fotos'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
