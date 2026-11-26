import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'data/local/app_database.dart';
import 'data/local/reporte_dao.dart';
import 'data/local/zona_dao.dart';
import 'data/remote/fuente_api_ecotrack.dart';
import 'data/repositories/repositorio_reportes_impl.dart';
import 'data/sensores/fuente_acelerometro.dart';
import 'data/services/servicio_alertas_local.dart';
import 'data/workmanager/tarea_periodica.dart';
import 'presentation/controllers/alerta_controller.dart';
import 'presentation/controllers/catalogo_controller.dart';
import 'presentation/controllers/formulario_controller.dart';
import 'presentation/controllers/reporte_controller.dart';
import 'presentation/views/ecotrack_app.dart';
import 'telemetria.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Modulo 5.2 - Telemetria global de errores
  // ---------------------------------------------------------------------------
  FlutterError.onError = (FlutterErrorDetails detalles) {
    // Muestra el error en consola con el formato estandar de Flutter...
    FlutterError.presentError(detalles);
    // ...y lo envia al recolector de telemetria.
    Telemetria.registrar(
      origen: 'FlutterError.onError',
      error: detalles.exception,
      pila: detalles.stack,
    );
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace pila) {
    // Errores no capturados de la plataforma: se registran y se devuelve
    // `true` para indicar que ya fueron manejados (la app no se cierra).
    Telemetria.registrar(
      origen: 'PlatformDispatcher.instance.onError',
      error: error,
      pila: pila,
    );
    return true;
  };

  // ---------------------------------------------------------------------------
  // Inyeccion de dependencias: data -> dominio -> presentation
  // ---------------------------------------------------------------------------
  final api = FuenteApiEcoTrack(cliente: http.Client());

  final repositorio = RepositorioReportesImpl(
    reportes: ReporteDao(AppDatabase.instancia),
    zonas: ZonaDao(AppDatabase.instancia),
    api: api,
  );

  // ---------------------------------------------------------------------------
  // Modulo 4: sensores, audio local, notificaciones y trabajo periodico.
  // ---------------------------------------------------------------------------
  final servicioAlertas = ServicioAlertasLocal();
  await servicioAlertas.inicializar();

  try {
    await configurarTareaPeriodica();
  } catch (_) {
    // Workmanager no esta disponible en todas las plataformas de escritorio.
  }

  final controladorAlertas = AlertaController(
    servicio: servicioAlertas,
    acelerometro: FuenteAcelerometro().lecturas(),
  );
  final controladorReportes = ReporteController(repositorio: repositorio);
  final controladorCatalogo = CatalogoController(repositorio: repositorio);
  final controladorFormulario = FormularioController();

  runApp(
    EcoTrackApp(
      reportes: controladorReportes,
      catalogo: controladorCatalogo,
      formulario: controladorFormulario,
      alertas: controladorAlertas,
    ),
  );

  // Estrategia Offline-First: primero se lee SQLite (siempre disponible) y,
  // cuando la conectividad lo permite, `CatalogoController.sincronizar()`
  // consulta la API REST con la cabecera Authorization: Bearer <token>.
  await Future.wait([
    controladorReportes.cargar(),
    controladorCatalogo.cargar(),
  ]);

  // Carga silenciosa del catalogo desde la nube (no bloquea la interfaz y
  // cualquier excepcion de red queda absorbida por el controlador).
  controladorCatalogo.sincronizar().ignore();
}
