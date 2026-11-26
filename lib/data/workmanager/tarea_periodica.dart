import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import '../../configuracion.dart';
import '../local/app_database.dart';
import '../local/reporte_dao.dart';
import '../remote/fuente_api_ecotrack.dart';
import '../sincronizacion/sincronizador_reportes.dart';

/// Modulo 4.3 - Nombre unico de la tarea periodica de sincronizacion.
const String tareaSincronizacion = 'sincronizarReportesPendientes';
const String tareaUnica = 'ecotrack_sincronizacion_periodica';

/// Id de la notificacion que informa el resultado de cada corrida.
const int idAvisoSincronizacion = 1003;

/// Modulo 4.3 - Punto de entrada del isolate en segundo plano.
///
/// `@pragma('vm:entry-point')` es obligatorio: Workmanager inicia un isolate
/// nuevo cuando la app esta cerrada; sin esta anotacion el compilador AOT podria
/// eliminar la funcion por parecer "no usada" y el callback nunca se encontraria.
@pragma('vm:entry-point')
void despachadorTareasEcoTrack() {
  Workmanager().executeTask((task, inputData) async {
    if (task != tareaSincronizacion) return true;

    try {
      // Cola offline real: DAO -> API -> marcar sincronizado.
      final sincronizados = await _sincronizarColaLocal();
      await _avisar(
        titulo: 'Sincronizacion de reportes',
        cuerpo: sincronizados > 0
            ? 'Se enviaron $sincronizados reportes pendientes a la nube.'
            : 'La cola offline ya estaba al dia (sin pendientes).',
      );
      return true;
    } catch (_) {
      // Fallo de red o de disco: se avisa y Workmanager reintenta mas tarde.
      await _avisar(
        titulo: 'Sincronizacion reprogramada',
        cuerpo: 'No se pudo enviar la cola offline; se reintentara.',
      );
      return false;
    }
  });
}

/// Registra la tarea periodica con la restriccion de red exigida.
///
/// Se llama desde `main()` despues de `WidgetsFlutterBinding.ensureInitialized()`.
Future<void> configurarTareaPeriodica() async {
  await Workmanager().initialize(despachadorTareasEcoTrack);
  await Workmanager().registerPeriodicTask(
    tareaUnica,
    tareaSincronizacion,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

/// Abre la base local dentro del isolate y sincroniza la cola pendiente.
///
/// Detalle clave: el isolate de Workmanager **no** tiene registrado el canal
/// nativo de `sqflite`, por lo que aqui se usa `sqflite_common_ffi` sobre el
/// mismo archivo `.db` que usa la app en primer plano.
Future<int> _sincronizarColaLocal() async {
  sqfliteFfiInit();
  final ruta = p.join(await getDatabasesPath(), AppDatabase.nombreArchivo);

  final db = await databaseFactoryFfi.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: AppDatabase.version,
      onCreate: AppDatabase.crearEsquema,
    ),
  );

  try {
    final sincronizador = SincronizadorReportes(
      dao: ReporteDao(() async => db),
      api: FuenteApiEcoTrack(cliente: http.Client()),
      token: AppConfig.tokenJwt,
    );
    return await sincronizador.sincronizar();
  } finally {
    await db.close();
  }
}

/// Aviso prioritario con el resultado de la corrida (nunca lanza: un fallo
/// del plugin no debe convertir una sincronizacion exitosa en un reintento).
Future<void> _avisar({
  required String titulo,
  required String cuerpo,
}) async {
  try {
    final notificaciones = FlutterLocalNotificationsPlugin();
    await notificaciones.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'ecotrack_emergencias',
        'Emergencias y envios EcoTrack',
        channelDescription: 'Avisos prioritarios de impacto en ruta y envios',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await notificaciones.show(
      id: idAvisoSincronizacion,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
    );
  } catch (_) {
    // El resultado de la sincronizacion ya se decidio antes de avisar.
  }
}
