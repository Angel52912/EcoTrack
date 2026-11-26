import 'package:ecotrack/domain/entities/reporte.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:ecotrack/domain/validadores/reglas_reporte.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

void main() {
  group('Reporte (domain) - aserciones y getters computados', () {
    test('Arrange: entidad valida | Act: leer getters | Assert: derivados', () {
      // Arrange
      final reporte = reporteDePrueba(prioridad: 5, categoria: 'Seguridad');

      // Act
      final critico = reporte.esCritico;
      final etiqueta = reporte.etiquetaPrioridad;
      final pendiente = reporte.pendienteDeSincronizar;
      final resumen = reporte.resumen;

      // Assert
      expect(critico, isTrue);
      expect(etiqueta, 'Critica');
      expect(pendiente, isTrue);
      expect(resumen, 'EC-2026-AL | Seguridad | Critica');
      expect(reporte.antiguedad, isA<Duration>());
    });

    test(
        'Arrange: codigo invalido | Act: instanciar entidad | '
        'Assert: la asercion interrumpe en desarrollo', () {
      // Arrange
      const codigoInvalido = 'ZZ-99';

      // Act
      Reporte construir() => reporteDePrueba(codigo: codigoInvalido);

      // Assert
      expect(construir, throwsAssertionError);
    });

    test(
        'Arrange: prioridad fuera de rango | Act: instanciar | '
        'Assert: la asercion falla', () {
      // Act / Assert
      expect(() => reporteDePrueba(prioridad: 9), throwsAssertionError);
      expect(() => reporteDePrueba(prioridad: 0), throwsAssertionError);
    });

    test(
        'Arrange: categoria desconocida | Act: instanciar | '
        'Assert: la asercion falla', () {
      // Act / Assert
      expect(() => reporteDePrueba(categoria: 'Inventada'), throwsAssertionError);
    });

    test('Arrange: dos reportes con el mismo id | Act: comparar | Assert: iguales', () {
      // Arrange
      final a = reporteDePrueba();
      final b = reporteDePrueba(titulo: 'Otro titulo distinto');

      // Act / Assert
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('Arrange: reporte sincronizado | Act: leer estado | Assert: false', () {
      // Arrange
      final reporte = reporteDePrueba(sincronizado: true);

      // Act
      final pendiente = reporte.pendienteDeSincronizar;

      // Assert
      expect(pendiente, isFalse);
      expect(reporte.sincronizado, isTrue);
    });
  });

  group('ReglasReporte - validacion con RegExp', () {
    test('Arrange: codigos | Act: validar con RegExp | Assert: resultados', () {
      // Arrange
      const validos = ['EC-2026-AL', 'EC-1234-ZZ'];
      const invalidos = ['EC-26-AL', 'ec-2026-al', 'EC-2026-A1', 'XX-2026-AL', ''];

      // Act / Assert
      for (final codigo in validos) {
        expect(ReglasReporte.validarCodigo(codigo), isNull,
            reason: '$codigo debia ser valido');
      }
      for (final codigo in invalidos) {
        expect(ReglasReporte.validarCodigo(codigo), isNotNull,
            reason: '$codigo debia ser rechazado');
      }
    });

    test('Arrange: titulos y detalles | Act: validar | Assert: limites', () {
      // Act / Assert
      expect(ReglasReporte.validarTitulo('Titulo corto'), isNull);
      expect(ReglasReporte.validarTitulo('abc'), isNotNull);
      expect(ReglasReporte.validarDetalle('Detalle suficientemente largo'),
          isNull);
      expect(ReglasReporte.validarDetalle('corto'), isNotNull);
    });
  });

  group('Zona (domain)', () {
    test('Arrange: zona de riesgo alto | Act: getters | Assert: atencion', () {
      // Arrange
      final zona = Zona(
        id: 'z_9',
        nombre: 'Tunel Subterraneo',
        ruta: 'RUTA-T09',
        riesgo: 4,
        entregasPendientes: 2,
        tipoIcono: Zona.tipoAlerta,
      );

      // Act
      final etiqueta = zona.etiquetaRiesgo;
      final requiere = zona.requiereAtencion;

      // Assert
      expect(etiqueta, 'Critica');
      expect(requiere, isTrue);
      expect(zona.avance, inInclusiveRange(0, 1));
    });

    test('Arrange: zona sana | Act: getters | Assert: sin atencion', () {
      // Arrange
      final zona = Zona(
        id: 'z_10',
        nombre: 'Deposito Tranquilo',
        ruta: 'RUTA-D10',
        riesgo: 1,
        entregasPendientes: 0,
        tipoIcono: Zona.tipoCamion,
      );

      // Act / Assert
      expect(zona.etiquetaRiesgo, 'Baja');
      expect(zona.requiereAtencion, isFalse);
      expect(zona.avance, 1.0);
    });
  });
}
