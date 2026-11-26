import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/alerta_impacto.dart';
import '../../domain/repositories/servicio_alertas.dart';

/// Modulo 4.2 y 4.3 - Implementacion real de audio + notificaciones locales.
///
/// Los plugins quedan confinados a `data`; el controlador y la vista solo
/// conocen [ServicioAlertas].
class ServicioAlertasLocal implements ServicioAlertas {
  ServicioAlertasLocal({
    AudioPlayer? reproductor,
    FlutterLocalNotificationsPlugin? notificaciones,
  })  : _reproductor = reproductor ?? AudioPlayer(),
        _notificaciones =
            notificaciones ?? FlutterLocalNotificationsPlugin();

  /// Ruta interna del asset registrado como `assets/audio/` en pubspec.yaml.
  static const String archivoAudio = 'audio/Aviso_Song.mp3';

  /// Canal Android con `Importance.max` (banner de alta prioridad).
  static const String idCanal = 'ecotrack_emergencias';
  static const String nombreCanal = 'Emergencias y envios EcoTrack';
  static const String descripcionCanal =
      'Avisos prioritarios de impacto en ruta y envios confirmados';

  static const int idEmergencia = 1001;
  static const int idEnvio = 1002;

  final AudioPlayer _reproductor;
  final FlutterLocalNotificationsPlugin _notificaciones;
  bool _inicializado = false;

  @override
  Future<void> inicializar() async {
    if (_inicializado) return;

    await _notificaciones.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    const canal = AndroidNotificationChannel(
      idCanal,
      nombreCanal,
      description: descripcionCanal,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final android = _notificaciones
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(canal);
    await android?.requestNotificationsPermission();

    _inicializado = true;
  }

  @override
  Future<void> reproducirAlerta() async {
    await _reproductor.stop();
    await _reproductor.play(AssetSource(archivoAudio));
  }

  @override
  Future<void> notificarEmergencia(AlertaImpacto alerta) => _mostrar(
        id: idEmergencia,
        titulo: 'Alerta de impacto en ruta',
        cuerpo: 'Eje ${alerta.eje}: ${alerta.magnitudFormateada} m/s² '
            '(${alerta.origen}). Revisa la carga y al personal.',
      );

  @override
  Future<void> notificarEnvioConfirmado(String codigo) => _mostrar(
        id: idEnvio,
        titulo: 'Envio confirmado',
        cuerpo: 'El reporte $codigo quedo registrado en la base local.',
      );

  Future<void> _mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        idCanal,
        nombreCanal,
        channelDescription: descripcionCanal,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificaciones.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: detalles,
      payload: titulo,
    );
  }

  /// Modulo 4.4: el `AudioPlayer` se libera aqui; la suscripcion al sensor se
  /// cancela en `AlertaController.dispose()`.
  @override
  void liberar() {
    _reproductor.stop().then((_) => _reproductor.dispose()).ignore();
  }
}
