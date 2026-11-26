import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

/// Modulo 4.3 - Nombre unico de la tarea periodica de sincronizacion.
const String tareaSincronizacion = 'sincronizarReportesPendientes';
const String tareaUnica = 'ecotrack_sincronizacion_periodica';

/// Modulo 4.3 - Punto de entrada del isolate en segundo plano.
///
/// `@pragma('vm:entry-point')` es obligatorio: Workmanager inicia un isolate
/// nuevo cuando la app esta cerrada; sin esta anotacion el compilador AOT podria
/// eliminar la funcion por parecer "no usada" y el callback nunca se encontraria.
@pragma('vm:entry-point')
void despachadorTareasEcoTrack() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == tareaSincronizacion) {
        await _avisarSincronizacion();
      }
      // `true` = trabajo completado; `false` permite a WorkManager reintentar.
      return true;
    } catch (_) {
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

/// Aviso prioritario emitido por el trabajo en segundo plano.
///
/// Aqui se concentraria la sincronizacion Offline-First (DAO -> API); la tarea
/// corrige fuera del arbol de widgets, por lo que no viola la regla de oro.
Future<void> _avisarSincronizacion() async {
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
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  await notificaciones.show(
    id: 1003,
    title: 'Sincronizacion de reportes',
    body: 'Hay conexion: los reportes pendientes pueden enviarse a la nube.',
    notificationDetails: detalles,
  );
}
