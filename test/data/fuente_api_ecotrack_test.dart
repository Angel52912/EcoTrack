import 'dart:convert';
import 'dart:io';

import 'package:ecotrack/data/remote/fuente_api_ecotrack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final base = Uri.parse('https://api.test/zonas');

  group('FuenteApiEcoTrack - Modulo 3.2 (API REST)', () {
    test(
        'Arrange: API 200 con JSON | Act: descargarZonas | '
        'Assert: decodifica e inyecta Authorization Bearer', () async {
      // Arrange
      http.Request? capturada;
      final cliente = MockClient((peticion) async {
        capturada = peticion;
        return http.Response(
          jsonEncode([
            {'id': 1, 'albumId': 7, 'title': 'zona del campo'},
            {'id': 2, 'albumId': 7, 'title': 'segunda zona'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final fuente = FuenteApiEcoTrack(cliente: cliente, base: base);

      // Act
      final zonas = await fuente.descargarZonas(token: 'jwt-de-prueba');

      // Assert
      expect(zonas, hasLength(2));
      expect(zonas.first.nombre, 'ZONA DEL CAMPO');
      expect(capturada, isNotNull);
      expect(capturada!.headers['Authorization'], 'Bearer jwt-de-prueba');
      expect(capturada!.url, base);
    });

    test(
        'Arrange: API con error HTTP 500 | Act: descargarZonas | '
        'Assert: se lanza ClientException (rethrow)', () {
      // Arrange
      final cliente = MockClient(
        (_) async => http.Response('Error interno del servidor', 500),
      );
      final fuente = FuenteApiEcoTrack(cliente: cliente, base: base);

      // Act
      final futuro = fuente.descargarZonas(token: 'jwt');

      // Assert
      expect(futuro, throwsA(isA<http.ClientException>()));
    });

    test(
        'Arrange: caida total de red | Act: descargarZonas | '
        'Assert: la excepcion de red se propaga intacta (rethrow)', () {
      // Arrange
      final cliente = MockClient(
        (_) async => throw const SocketException('Connection refused'),
      );
      final fuente = FuenteApiEcoTrack(cliente: cliente, base: base);

      // Act
      final futuro = fuente.descargarZonas(token: 'jwt');

      // Assert
      expect(futuro, throwsA(isA<SocketException>()));
    });

    test(
        'Arrange: JSON corrupto con HTTP 200 | Act: descargarZonas | '
        'Assert: propaga FormatException', () {
      // Arrange
      final cliente = MockClient(
        (_) async => http.Response('<html>no soy json</html>', 200),
      );
      final fuente = FuenteApiEcoTrack(cliente: cliente, base: base);

      // Act
      final futuro = fuente.descargarZonas(token: 'jwt');

      // Assert
      expect(futuro, throwsA(isA<FormatException>()));
    });
  });
}
