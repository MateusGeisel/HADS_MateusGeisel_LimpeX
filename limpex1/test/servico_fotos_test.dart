import 'package:flutter_test/flutter_test.dart';
import 'package:limpex1/services/prestador_service.dart';

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
}
