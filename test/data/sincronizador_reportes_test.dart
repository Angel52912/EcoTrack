import 'package:ecotrack/data/local/app_database.dart';
import 'package:ecotrack/data/local/reporte_dao.dart';
import 'package:ecotrack/data/models/reporte_model.dart';
import 'package:ecotrack/data/remote/fuente_api_ecotrack.dart';
import 'package:ecotrack/data/sincronizacion/sincronizador_reportes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../fixtures/repositorio_falso.dart';

/// Modulo 3.3 - Pruebas de la sincronizacion real de la cola offline
/// (DAO -> API -> marcar sincronizado), con SQLite en memoria y `MockClient`.
void main() {
  late Database base;
  late ReporteDao dao;
  final baseReportes = Uri.parse('https://api.test/reportes');

  FuenteApiEcoTrack fuenteCon(MockClient cliente) =>
      FuenteApiEcoTrack(cliente: cliente, baseReportes: baseReportes);

  SincronizadorReportes sincronizadorCon(FuenteApiEcoTrack api) =>
      SincronizadorReportes(
        dao: dao,
        api: api,
        token: 'jwt-de-prueba',
      );

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
  });

  tearDown(() => base.close());

  test(
      'Arrange: dos reportes pendientes y API 201 | Act: sincronizar() | '
      'Assert: se envian los dos, se marcan y viaja el Bearer', () async {
    // Arrange
    await dao.insertar(ReporteModel.deEntidad(
      reporteDePrueba(id: 'r_a', categoria: 'Carga', prioridad: 5),
    ).toMap());
    await dao.insertar(ReporteModel.deEntidad(
      reporteDePrueba(id: 'r_b', categoria: 'Ruta', prioridad: 2),
    ).toMap());

    final peticiones = <http.Request>[];
    final api = fuenteCon(MockClient((peticion) async {
      peticiones.add(peticion);
      return http.Response('{}', 201,
          headers: {'content-type': 'application/json'});
    }));

    // Act
    final enviados = await sincronizadorCon(api).sincronizar();

    // Assert
    expect(enviados, 2);
    expect(await dao.pendientesDeSincronizar(), isEmpty,
        reason: 'La cola offline debe quedar vacia tras confirmar la API');
    expect(peticiones, hasLength(2));
    expect(peticiones.every((p) => p.url == baseReportes), isTrue);
    expect(peticiones.first.headers['Authorization'], 'Bearer jwt-de-prueba');
  });

  test(
      'Arrange: cola vacia | Act: sincronizar() | '
      'Assert: devuelve 0 y no se hace ninguna peticion', () async {
    // Arrange
    var llamadas = 0;
    final api = fuenteCon(MockClient((_) async {
      llamadas++;
      return http.Response('{}', 201);
    }));

    // Act
    final enviados = await sincronizadorCon(api).sincronizar();

    // Assert
    expect(enviados, 0);
    expect(llamadas, 0,
        reason: 'Sin pendientes no debe gastarse un solo request');
  });

  test(
      'Arrange: un reporte pendiente y API 500 | Act: sincronizar() | '
      'Assert: se propaga el error y el reporte sigue pendiente', () async {
    // Arrange
    await dao.insertar(ReporteModel.deEntidad(
      reporteDePrueba(id: 'r_c', categoria: 'Carga', prioridad: 4),
    ).toMap());
    final api = fuenteCon(
      MockClient((_) async => http.Response('error interno', 500)),
    );

    // Act
    final futuro = sincronizadorCon(api).sincronizar();

    // Assert
    await expectLater(futuro, throwsA(isA<http.ClientException>()));
    final pendientes = await dao.pendientesDeSincronizar();
    expect(pendientes, hasLength(1),
        reason: 'Nunca se marca sin confirmacion 2xx de la API');
    expect(pendientes.single['id'], 'r_c');
  });

  test(
      'Arrange: tres pendientes y fallo en el segundo | Act: sincronizar() | '
      'Assert: el primero queda enviado y el fallo corta la corrida', () async {
    // Arrange
    for (final (indice, id) in ['r_1', 'r_2', 'r_3'].indexed) {
      await dao.insertar(ReporteModel.deEntidad(
        reporteDePrueba(id: id, categoria: 'Carga', prioridad: indice + 1),
      ).toMap());
    }

    var llamadas = 0;
    final api = fuenteCon(MockClient((_) async {
      llamadas++;
      if (llamadas == 2) return http.Response('caida', 503);
      return http.Response('{}', 201);
    }));

    // Act
    final sincronizador = sincronizadorCon(api);
    await expectLater(sincronizador.sincronizar(),
        throwsA(isA<http.ClientException>()));

    // Assert
    expect(llamadas, 2, reason: 'El fallo detiene la corrida en curso');
    expect(sincronizador.ultimosSincronizados, 1,
        reason: 'Solo el primero llego a confirmarse antes del fallo');
    final pendientes = await dao.pendientesDeSincronizar();
    expect(pendientes, hasLength(2),
        reason: 'Solo se marca lo confirmado: r_1 salio, r_2 y r_3 esperan');
    expect(pendientes.map((fila) => fila['id']), isNot(contains('r_1')));
  });
}
