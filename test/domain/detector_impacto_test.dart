import 'package:ecotrack/domain/entities/lectura_acelerometro.dart';
import 'package:ecotrack/domain/validadores/detector_impacto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Modulo 4.1 - DetectorImpacto (umbral 15.0 m/s2)', () {
    test(
        'Arrange: lecturas por debajo del umbral | Act: evaluar | '
        'Assert: no hay alerta', () {
      final lectura = LecturaAcelerometro(x: 14.9, y: 3.2, z: -8.4);

      expect(DetectorImpacto.evaluar(lectura), isNull);
    });

    test(
        'Arrange: eje X por encima del umbral | Act: evaluar | '
        'Assert: alerta en X con la magnitud absoluta', () {
      final lectura = LecturaAcelerometro(x: 18.2, y: 1.0, z: 2.0);

      final alerta = DetectorImpacto.evaluar(lectura);

      expect(alerta, isNotNull);
      expect(alerta!.eje, 'X');
      expect(alerta.magnitud, 18.2);
      expect(alerta.simulada, isFalse);
    });

    test(
        'Arrange: eje Y negativo fuerte | Act: evaluar | '
        'Assert: tambien dispara (valor absoluto)', () {
      final lectura = LecturaAcelerometro(x: 1.0, y: -21.5, z: 4.0);

      expect(DetectorImpacto.evaluar(lectura)!.eje, 'Y');
    });

    test(
        'Arrange: eje Z por encima del umbral | Act: evaluar | '
        'Assert: alerta en Z', () {
      final lectura = LecturaAcelerometro(x: 0.5, y: 2.0, z: 15.6);

      final alerta = DetectorImpacto.evaluar(lectura);

      expect(alerta, isNotNull);
      expect(alerta!.eje, 'Z');
    });

    test(
        'Arrange: umbral exacto | Act: evaluar | '
        'Assert: no dispara porque debe SUPERAR 15.0', () {
      final lectura = LecturaAcelerometro(x: 15.0, y: 0, z: 0);

      expect(DetectorImpacto.evaluar(lectura), isNull);
    });

    test(
        'Arrange: simulacion manual | Act: DetectorImpacto.simular() | '
        'Assert: supera el umbral y queda marcada como simulada', () {
      final alerta = DetectorImpacto.simular();

      expect(alerta.simulada, isTrue);
      expect(alerta.magnitud, greaterThan(DetectorImpacto.umbral));
      expect(alerta.origen, 'Simulacion manual');
    });
  });
}
