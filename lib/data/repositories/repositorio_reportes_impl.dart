import '../../domain/entities/reporte.dart';
import '../../domain/entities/zona.dart';
import '../../domain/repositories/repositorio_reportes.dart';
import '../local/reporte_dao.dart';
import '../local/zona_dao.dart';
import '../models/reporte_model.dart';
import '../models/zona_model.dart';
import '../remote/fuente_api_ecotrack.dart';
import '../sincronizacion/sincronizador_reportes.dart';

/// Modulo 1 y Modulo 3 - Puente entre el dominio y las fuentes de datos.
///
/// Implementa el puerto `RepositorioReportes` uniendo:
///  * fuente local (SQLite/DAO) -> Offline-First, primera en responder;
///  * fuente remota (API REST) -> se consulta solo cuando hay conectividad
///    y sus excepciones se propagan (`rethrow`) hasta el controlador.
class RepositorioReportesImpl implements RepositorioReportes {
  RepositorioReportesImpl({
    required ReporteDao reportes,
    required ZonaDao zonas,
    required FuenteApiEcoTrack api,
  })  : _reportes = reportes,
        _zonas = zonas,
        _api = api;

  final ReporteDao _reportes;
  final ZonaDao _zonas;
  final FuenteApiEcoTrack _api;

  @override
  Future<List<Reporte>> obtenerReportes({String? categoria}) async {
    final filas = await _reportes.consultar(categoria: categoria);
    return filas.map(ReporteModel.fromMap).toList(growable: false);
  }

  @override
  Future<void> guardarReporte(Reporte reporte) async {
    await _reportes.insertar(ReporteModel.deEntidad(reporte).toMap());
  }

  @override
  Future<void> eliminarReporte(String id) async {
    await _reportes.eliminar(id);
  }

  @override
  Future<List<Zona>> obtenerZonas() async {
    final filas = await _zonas.consultar();
    return filas.map(ZonaModel.fromMap).toList(growable: false);
  }

  @override
  Future<void> guardarZonas(List<Zona> zonas) async {
    await _zonas.reemplazar(
      zonas.map(ZonaModel.deEntidad).map((m) => m.toMap()).toList(growable: false),
    );
  }

  @override
  Future<List<Zona>> descargarZonas({required String token}) {
    // Las excepciones de red NO se tragan aqui: se repropagan al controlador.
    return _api.descargarZonas(token: token);
  }

  @override
  Future<int> sincronizarReportesPendientes({required String token}) {
    // Misma logica que usa la tarea periodica de Workmanager: DAO -> API ->
    // marcar. Las excepciones se repropagan para que el llamador informe.
    return SincronizadorReportes(
      dao: _reportes,
      api: _api,
      token: token,
    ).sincronizar();
  }
}
