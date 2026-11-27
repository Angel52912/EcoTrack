import 'package:ecotrack/configuracion.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:ecotrack/presentation/controllers/catalogo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

void main() {
  late RepositorioFalso repositorio;
  late CatalogoController controlador;

  setUp(() {
    // Arrange
    repositorio = RepositorioFalso()
      ..zonas.addAll([
        Zona(
          id: 'z_1',
          nombre: 'Zona Segura',
          ruta: 'RUTA-A1',
          riesgo: 1,
          entregasPendientes: 1,
          tipoIcono: Zona.tipoCamion,
        ),
        Zona(
          id: 'z_2',
          nombre: 'Zona Peligrosa',
          ruta: 'RUTA-B2',
          riesgo: 4,
          entregasPendientes: 15,
          tipoIcono: Zona.tipoAlerta,
        ),
      ]);
    controlador = CatalogoController(repositorio: repositorio);
  });

  tearDown(() => controlador.dispose());

  test('Arrange: catalogo local | Act: cargar() | Assert: zonas disponibles',
      () async {
    // Act
    await controlador.cargar();

    // Assert
    expect(controlador.zonas, hasLength(2));
    expect(controlador.zonasFiltradas, hasLength(2));
    expect(controlador.totalAtencion, 1);
    expect(controlador.cargando, isFalse);
  });

  test(
      'Arrange: filtro de riesgo 4 | Act: aplicarFiltroDeRiesgo | '
      'Assert: solo esa zona y notificacion', () async {
    // Arrange
    await controlador.cargar();
    var notificaciones = 0;
    controlador.addListener(() => notificaciones++);

    // Act
    await controlador.aplicarFiltroDeRiesgo(4);

    // Assert
    expect(controlador.riesgoActivo, 4);
    expect(controlador.zonasFiltradas, hasLength(1));
    expect(controlador.zonasFiltradas.single.nombre, 'Zona Peligrosa');
    expect(notificaciones, 1);
  });

  test(
      'Arrange: red disponible | Act: sincronizar() | '
      'Assert: descarga con Bearer token y reemplaza el catalogo', () async {
    // Act
    await controlador.sincronizar();

    // Assert
    expect(repositorio.descargasRealizadas, 1);
    expect(repositorio.ultimoToken, AppConfig.tokenJwt);
    expect(controlador.zonas, hasLength(2));
    expect(controlador.zonas.first.nombre, 'ZONA REMOTA ORIENTE');
    expect(controlador.estadoRed, contains('Sincronizado'));
    expect(controlador.sincronizando, isFalse);
  });

  test(
      'Arrange: sin conexion | Act: sincronizar() | '
      'Assert: Offline-First: catalogo local intacto y sin excepcion',
      () async {
    // Arrange
    await controlador.cargar();
    repositorio.redCaida = true;

    // Act
    await controlador.sincronizar();

    // Assert
    expect(controlador.zonas, hasLength(2),
        reason: 'Los datos locales no se pierden al fallar la red');
    expect(controlador.zonas.first.nombre, 'Zona Segura');
    expect(controlador.estadoRed, contains('Sin conexion'));
    expect(controlador.sincronizando, isFalse);
  });

  test(
      'Arrange: 2 reportes pendientes y red OK | Act: sincronizar() | '
      'Assert: la cola se envia y el mensaje lo informa', () async {
    // Arrange
    repositorio.reportes
      ..add(reporteDePrueba(id: 'r_p1'))
      ..add(reporteDePrueba(id: 'r_p2', codigo: 'EC-2026-BR'));

    // Act
    await controlador.sincronizar();

    // Assert
    expect(repositorio.reportesEnviados, 2,
        reason: 'El boton "Sincronizar" debe subir la cola de reportes');
    expect(repositorio.reportes.every((r) => r.sincronizado), isTrue,
        reason: 'Solo se marcan tras confirmar la API');
    expect(controlador.estadoRed, contains('2 reportes enviados'));
    expect(repositorio.ultimoToken, AppConfig.tokenJwt);
  });

  test(
      'Arrange: reportes pendientes sin conexion | Act: sincronizar() | '
      'Assert: la cola sigue pendiente (nunca se marca sin 2xx)', () async {
    // Arrange
    repositorio.reportes.add(reporteDePrueba(id: 'r_off'));
    repositorio.redCaida = true;

    // Act
    await controlador.sincronizar();

    // Assert
    expect(repositorio.reportesEnviados, 0);
    expect(repositorio.reportes.single.pendienteDeSincronizar, isTrue,
        reason: 'Offline-First: sin confirmacion no se marca');
    expect(controlador.estadoRed, contains('Sin conexion'));
  });
}
