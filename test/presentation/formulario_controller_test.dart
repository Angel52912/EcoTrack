import 'package:ecotrack/presentation/controllers/formulario_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FormularioController formulario;
  late int notificaciones;

  setUp(() {
    // Arrange
    formulario = FormularioController();
    notificaciones = 0;
    formulario.addListener(() => notificaciones++);
  });

  tearDown(() => formulario.dispose());

  group('FormularioController - Material 3 y validaciones', () {
    test(
        'Arrange: sin terminos | Act: leer puedeEnviar | '
        'Assert: el boton debe quedar bloqueado', () {
      // Act
      final bloqueado = formulario.puedeEnviar;

      // Assert
      expect(bloqueado, isFalse,
          reason: 'onPressed: null hasta aceptar los terminos');
    });

    test(
        'Arrange: terminos aceptados | Act: asignarTerminos(true) | '
        'Assert: habilita el envio y notifica', () {
      // Act
      formulario.asignarTerminos(true);

      // Assert
      expect(formulario.puedeEnviar, isTrue);
      expect(formulario.aceptaTerminos, isTrue);
      expect(notificaciones, 1);
    });

    test(
        'Arrange: captura invalida | Act: construirReporte() | '
        'Assert: devuelve null (RegEx del dominio)', () {
      // Arrange
      formulario.asignarTerminos(true);

      // Act
      formulario.asignarCodigo('codigo-malo');
      formulario.asignarTitulo('Titulo correcto');
      formulario.asignarDetalle('Detalle con mas de diez caracteres');

      // Assert
      expect(formulario.construirReporte(), isNull);
    });

    test(
        'Arrange: captura valida | Act: construirReporte() | '
        'Assert: entidad lista para SQLite con sincronizacion pendiente',
        () {
      // Arrange
      formulario.asignarTerminos(true);
      formulario.asignarCodigo('  ec-2026-al  '); // se normaliza a mayusculas
      formulario.asignarTitulo('Fuga reportada en campo');
      formulario.asignarDetalle('Detalle suficientemente largo para validar');
      formulario.asignarCategoria('Ambiental');
      formulario.asignarPrioridad(5);

      // Act
      final reporte = formulario.construirReporte();

      // Assert
      expect(reporte, isNotNull);
      expect(reporte!.codigo, 'EC-2026-AL');
      expect(reporte.categoria, 'Ambiental');
      expect(reporte.prioridad, 5);
      expect(reporte.esCritico, isTrue);
      expect(reporte.pendienteDeSincronizar, isTrue);
      expect(reporte.id, startsWith('r_'));
    });

    test(
        'Arrange: formulario cargado | Act: restablecer() | '
        'Assert: vuelve al estado inicial y bloquea de nuevo', () {
      // Arrange
      formulario.asignarTerminos(true);
      formulario.asignarTitulo('Titulo cargado');
      formulario.asignarPrioridad(5);
      final notificacionesPrevias = notificaciones;

      // Act
      formulario.restablecer();

      // Assert
      expect(formulario.titulo, isEmpty);
      expect(formulario.prioridad, 3);
      expect(formulario.categoria, 'Ruta');
      expect(formulario.puedeEnviar, isFalse);
      expect(notificaciones, notificacionesPrevias + 1,
          reason: 'restablecer() debe notificar un unico repintado');
    });

    test(
        'Arrange: sin terminos | Act: construirReporte() | '
        'Assert: jamas construye entidad (doble proteccion)', () {
      // Arrange: campos validos pero terminos NO aceptados.
      formulario.asignarCodigo('EC-2026-AL');
      formulario.asignarTitulo('Titulo correcto de prueba');
      formulario.asignarDetalle('Detalle suficientemente largo');

      // Act / Assert
      expect(formulario.construirReporte(), isNull);
    });
  });
}
