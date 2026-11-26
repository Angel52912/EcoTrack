import '../local/reporte_dao.dart';
import '../remote/fuente_api_ecotrack.dart';

/// Modulo 3.3 + Módulo 4.3 - Sincronizacion real de la cola offline.
///
/// Consume el patron DAO (unico autorizado a escribir SQL) y la fuente API
/// (unico autorizada a hacer HTTP). No conoce plugins, isolate ni UI: esta
/// misma clase se usa desde el `main()` de la app y desde la tarea periodica
/// de Workmanager, y por eso es directamente testeable con SQLite en memoria
/// y un `MockClient`.
class SincronizadorReportes {
  SincronizadorReportes({
    required ReporteDao dao,
    required FuenteApiEcoTrack api,
    required String token,
  })  : _dao = dao,
        _api = api,
        _token = token;

  final ReporteDao _dao;
  final FuenteApiEcoTrack _api;
  final String _token;

  /// Numero de reportes que quedaron marcados como sincronizados en la
  /// ultima corrida (util para la notificacion de la tarea periodica).
  int ultimosSincronizados = 0;

  /// Envia todos los reportes pendientes y los marca uno por uno.
  ///
  /// Contrato Offline-First:
  ///  * un reporte solo se marca **despues** de que la API confirmo 2xx;
  ///  * si un envio falla, la excepcion se propaga y lo demas queda en la
  ///    cola para el reintento de Workmanager (`return false` -> retry);
  ///  * los que ya se enviaron no se repiten en la siguiente corrida.
  Future<int> sincronizar() async {
    ultimosSincronizados = 0;
    final pendientes = await _dao.pendientesDeSincronizar();

    for (final registro in pendientes) {
      await _api.subirReporte(reporte: registro, token: _token);
      await _dao.marcarSincronizado(registro['id'] as String);
      ultimosSincronizados++;
    }
    return ultimosSincronizados;
  }
}
