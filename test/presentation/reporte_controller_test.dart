import 'package:ecotrack/presentation/controllers/reporte_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

void main() {
  late RepositorioFalso repositorio;
  late ReporteController controlador;
  late int notificaciones;

  setUp(() {
    // Arrange
    repositorio = RepositorioFalso()
      ..reportes.addAll([
        reporteDePrueba(id: 'r_1', titulo: 'Fuga en tanque principal',
            categoria: 'Carga', prioridad: 5),
        reporteDePrueba(id: 'r_2', titulo: 'Bache en ruta rural',
            categoria: 'Ruta', prioridad: 2),
        reporteDePrueba(id: 'r_3', titulo: 'Conductor sin elementos',
            categoria: 'Seguridad', prioridad: 4),
      ]);
    controlador = ReporteController(repositorio: repositorio);
    notificaciones = 0;
    controlador.addListener(() => notificaciones++);
  });

  tearDown(() => controlador.dispose());

  test('Arrange: base local | Act: cargar() | Assert: lista y notificacion',
      () async {
    // Act
    await controlador.cargar();

    // Assert
    expect(controlador.reportes, hasLength(3));
    expect(controlador.cargando, isFalse);
    expect(controlador.error, isNull);
    expect(notificaciones, greaterThanOrEqualTo(2),
        reason: 'notifyListeners() debe avisar inicio y fin de la carga');
  });

  test(
      'Arrange: filtro "Carga" | Act: aplicarFiltro | '
      'Assert: el DAO recibe la categoria y solo quedan sus reportes',
      () async {
    // Act
    await controlador.aplicarFiltro('Carga');

    // Assert
    expect(repositorio.ultimaCategoriaConsultada, 'Carga');
    expect(controlador.categoriaActiva, 'Carga');
    expect(controlador.reportes, hasLength(1));
    expect(controlador.reportes.single.titulo, 'Fuga en tanque principal');
    expect(notificaciones, greaterThanOrEqualTo(2));
  });

  test('Arrange: filtro nulo | Act: aplicarFiltro(null) | Assert: todo', () async {
    // Act
    await controlador.aplicarFiltro('Ruta');
    await controlador.aplicarFiltro(null);

    // Assert
    expect(repositorio.ultimaCategoriaConsultada, isNull);
    expect(controlador.reportes, hasLength(3));
  });

  test(
      'Arrange: reporte nuevo | Act: agregar() | '
      'Assert: persiste localmente y recarga', () async {
    // Arrange
    final nuevo = reporteDePrueba(
      id: 'r_4',
      codigo: 'EC-2026-ZZ',
      titulo: 'Reporte recien capturado',
    );

    // Act
    final guardado = await controlador.agregar(nuevo);

    // Assert
    expect(guardado, isTrue);
    expect(repositorio.reportes, hasLength(4));
    expect(controlador.reportes, hasLength(4));
    expect(controlador.error, isNull);
  });

  test(
      'Arrange: fallo de disco | Act: agregar() | '
      'Assert: no lanza y expone el error (degrada sin romper)', () async {
    // Arrange: primero hay datos en memoria (como tras un arranque normal).
    await controlador.cargar();
    repositorio.fallarAlGuardar = true;

    // Act
    final guardado = await controlador.agregar(reporteDePrueba(id: 'r_x'));

    // Assert
    expect(guardado, isFalse);
    expect(controlador.error, contains('No se pudo guardar'));
    expect(controlador.reportes, hasLength(3));
  });

  test(
      'Arrange: eliminacion | Act: eliminar() | '
      'Assert: quita el registro del listado', () async {
    // Act
    await controlador.eliminar('r_2');

    // Assert
    expect(controlador.reportes, hasLength(2));
    expect(controlador.reportes.map((r) => r.id), isNot(contains('r_2')));
  });

  test(
      'Arrange: estado previo | Act: limpiarEstadoRed() | '
      'Assert: notifica un unico cambio', () async {
    // Arrange
    await controlador.cargar();
    final antes = notificaciones;

    // Act
    controlador.limpiarEstadoRed();

    // Assert: sin cambios de estado no debe repintar de mas.
    expect(notificaciones, antes);
  });

  test(
      'Arrange: primer controlador con datos | Act: crear un segundo y cargar '
      'con el mismo repositorio | Assert: los datos sobreviven (Offline-First)',
      () async {
    // Arrange
    await controlador.agregar(reporteDePrueba(id: 'r_persistido'));

    // Act (simula el cierre total y reapertura de la app)
    final reabierto = ReporteController(repositorio: repositorio);
    await reabierto.cargar();

    // Assert
    expect(reabierto.reportes.map((r) => r.id), contains('r_persistido'));

    // Limpieza de recursos (sin fugas de memoria).
    reabierto.dispose();
  });

  test(
      'Arrange: reportes | Act: leer getters computados | '
      'Assert: contadores del panel', () async {
    // Act
    await controlador.cargar();

    // Assert
    expect(controlador.total, 3);
    expect(controlador.totalCriticos, 2);
    expect(controlador.pendientesDeSincronizar, 3);
    expect(controlador.categoriasDisponibles, contains('Ambiental'));
    expect(controlador.estadoRed, isNull);
  });
}
