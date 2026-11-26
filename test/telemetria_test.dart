import 'package:ecotrack/telemetria.dart';
import 'package:flutter_test/flutter_test.dart';

/// Modulo 5.2 - Telemetria de errores capturada por `main.dart`.
void main() {
  setUp(Telemetria.limpiar);

  group('Telemetria', () {
    test('Arrange: historial limpio | Act: registrar | Assert: evento guardado',
        () {
      // Act
      Telemetria.registrar(
        origen: 'FlutterError.onError',
        error: StateError('fallo de prueba'),
        pila: StackTrace.current,
      );

      // Assert
      expect(Telemetria.total, 1);
      expect(Telemetria.errores.single['origen'], 'FlutterError.onError');
      expect(Telemetria.errores.single['error'], contains('fallo de prueba'));
      expect(Telemetria.errores.single['pila'], isNot('sin traza'));
      expect(Telemetria.errores.single['fecha'], isA<String>());
    });

    test(
        'Arrange: varios errores | Act: superar el limite | '
        'Assert: solo conserva los ultimos N', () {
      // Act
      for (var i = 0; i < Telemetria.limiteDeEventos + 10; i++) {
        Telemetria.registrar(origen: 'PlatformDispatcher', error: 'error $i');
      }

      // Assert
      expect(Telemetria.total, Telemetria.limiteDeEventos);
      expect(Telemetria.errores.first['error'], 'error 59');
    });

    test('Arrange: historial lleno | Act: limpiar | Assert: vacio', () {
      // Arrange
      Telemetria.registrar(origen: 'x', error: 'y');
      expect(Telemetria.total, 1);

      // Act
      Telemetria.limpiar();

      // Assert
      expect(Telemetria.total, 0);
      expect(Telemetria.errores, isEmpty);
    });
  });
}
