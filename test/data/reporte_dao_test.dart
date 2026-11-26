import 'package:ecotrack/data/local/app_database.dart';
import 'package:ecotrack/data/local/reporte_dao.dart';
import 'package:ecotrack/data/models/reporte_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../fixtures/repositorio_falso.dart';

/// Modulo 3.1 - Pruebas del patron DAO con SQLite en memoria.
///
/// Demuestra el uso de columnas explicitas y de parametros posicionales
/// (`whereArgs`), incluyendo un intento de Inyeccion SQL.
void main() {
  late Database base;
  late ReporteDao dao;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    base = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.version,
        onCreate: AppDatabase.crearEsquema,
      ),
    );
    dao = ReporteDao(() async => base);

    // Arrange: dos reportes de categorias distintas.
    await dao.insertar(
      ReporteModel.deEntidad(
        reporteDePrueba(id: 'r_a', categoria: 'Carga', prioridad: 5),
      ).toMap(),
    );
    await dao.insertar(
      ReporteModel.deEntidad(
        reporteDePrueba(id: 'r_b', categoria: 'Ruta', prioridad: 2),
      ).toMap(),
    );
  });

  tearDown(() => base.close());

  test('Arrange: dos filas | Act: consultar | Assert: columnas explicitas',
      () async {
    // Arrange: datos preparados en setUp().

    // Act
    final filas = await dao.consultar();

    // Assert
    expect(filas, hasLength(2));
    for (final fila in filas) {
      expect(fila.keys.toList(), ReporteDao.columnas,
          reason: 'Nunca debe existir SELECT * en la consulta');
    }
  });

  test(
      'Arrange: filtro por categoria | Act: consultar(categoria) | '
      'Assert: solo esa categoria viaja en whereArgs', () async {
    // Act
    final cargas = await dao.consultar(categoria: 'Carga');
    final rutas = await dao.consultar(categoria: 'Ruta');

    // Assert
    expect(cargas, hasLength(1));
    expect(cargas.single['categoria'], 'Carga');
    expect(rutas, hasLength(1));
    expect(rutas.single['categoria'], 'Ruta');
    expect(await dao.contar(categoria: 'Carga'), 1);
  });

  test(
      'Arrange: payload de Inyeccion SQL | Act: usarlo como parametro | '
      'Assert: no se filtra nada (parametrizado, no concatenado)', () async {
    // Arrange
    const ataque = "' OR '1'='1";

    // Act
    final filas = await dao.consultar(categoria: ataque);

    // Assert
    expect(filas, isEmpty,
        reason: 'El valor viaja como dato (?), jamas se interpreta como SQL');
  });

  test('Arrange: registro | Act: eliminar por id | Assert: desaparece', () async {
    // Act
    await dao.eliminar('r_a');

    // Assert
    expect(await dao.contar(), 1);
    expect(await dao.consultar(categoria: 'Carga'), isEmpty);
  });

  test(
      'Arrange: registro pendiente | Act: marcarSincronizado | '
      'Assert: sale de la cola offline', () async {
    // Act
    await dao.marcarSincronizado('r_a');

    // Assert
    expect(await dao.pendientesDeSincronizar(), hasLength(1));
    expect((await dao.consultar(categoria: 'Carga')).single['sincronizado'], 1);
  });
}
