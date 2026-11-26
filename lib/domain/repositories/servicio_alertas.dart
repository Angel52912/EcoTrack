import '../entities/alerta_impacto.dart';

/// Modulo 4.2 y 4.3 - Puerto del dominio para efectos externos.
///
/// `presentation` solo conoce esta interfaz: no importa `audioplayers` ni
/// `flutter_local_notifications`. La implementacion real vive en `data`.
abstract class ServicioAlertas {
  /// Prepara permisos y canales de notificacion (idempotente).
  Future<void> inicializar();

  /// Reproduce el audio local `assets/audio/Aviso_Song.mp3`.
  Future<void> reproducirAlerta();

  /// Muestra un aviso de alta prioridad al detectar una emergencia.
  Future<void> notificarEmergencia(AlertaImpacto alerta);

  /// Muestra el aviso al confirmar un envio en el formulario.
  Future<void> notificarEnvioConfirmado(String codigo);

  /// Libera el reproductor multimedia.
  void liberar();
}
