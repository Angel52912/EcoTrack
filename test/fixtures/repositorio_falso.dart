import 'package:ecotrack/domain/entities/reporte.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:ecotrack/domain/repositories/repositorio_reportes.dart';

/// Doble de prueba (Fake) del puerto `RepositorioReportes`.
///
/// Permite probar controladores y vistas sin SQLite ni red, y ademas
/// registrar que parametros llegaron a cada llamada.
class RepositorioFalso implements RepositorioReportes {
  final List<Reporte> reportes = [];
  final List<Zona> zonas = [];

  /// Ultima categoria solicitada al DAO (demuestra el filtro por whereArgs).
  String? ultimaCategoriaConsultada;

  /// Ultimo token inyectado en la cabecera Authorization.
  String? ultimoToken;

  int descargasRealizadas = 0;

  /// Reportes que la ultima sincronizacion confirmo ante la nube.
  int reportesEnviados = 0;

  /// Simula fallo de escritura local.
  bool fallarAlGuardar = false;

  /// Simula falta de conectividad en la API REST.
  bool redCaida = false;

  @override
  Future<List<Reporte>> obtenerReportes({String? categoria}) async {
    ultimaCategoriaConsultada = categoria;
    if (categoria == null) return List.of(reportes);
    return reportes.where((r) => r.categoria == categoria).toList();
  }

  @override
  Future<void> guardarReporte(Reporte reporte) async {
    if (fallarAlGuardar) throw Exception('SQLite: disco local no disponible');
    reportes.removeWhere((r) => r.id == reporte.id);
    reportes.add(reporte);
  }

  @override
  Future<void> eliminarReporte(String id) async {
    reportes.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<Zona>> obtenerZonas() async => List.of(zonas);

  @override
  Future<void> guardarZonas(List<Zona> nuevas) async {
    zonas
      ..clear()
      ..addAll(nuevas);
  }

  @override
  Future<List<Zona>> descargarZonas({required String token}) async {
    descargasRealizadas += 1;
    ultimoToken = token;
    if (redCaida) {
      throw Exception('SocketException: connection refused');
    }
    return [
      Zona(
        id: 'z_remota_1',
        nombre: 'ZONA REMOTA ORIENTE',
        ruta: 'RUTA-R01',
        riesgo: 4,
        entregasPendientes: 9,
        tipoIcono: Zona.tipoAlerta,
      ),
      Zona(
        id: 'z_remota_2',
        nombre: 'ZONA REMOTA PONIENTE',
        ruta: 'RUTA-R02',
        riesgo: 2,
        entregasPendientes: 2,
        tipoIcono: Zona.tipoCamion,
      ),
    ];
  }

  @override
  Future<int> sincronizarReportesPendientes({required String token}) async {
    ultimoToken = token;
    if (redCaida) {
      throw Exception('SocketException: connection refused');
    }

    final pendientes = reportes
        .where((r) => r.pendienteDeSincronizar)
        .toList(growable: false);
    if (pendientes.isEmpty) return 0;

    // Solo se marcan como sincronizados tras "confirmar" la API (2xx).
    reportes
      ..clear()
      ..addAll([
        for (final r in reportes)
          r.pendienteDeSincronizar
              ? Reporte(
                  id: r.id,
                  codigo: r.codigo,
                  titulo: r.titulo,
                  detalle: r.detalle,
                  categoria: r.categoria,
                  prioridad: r.prioridad,
                  registradoEn: r.registradoEn,
                  sincronizado: true,
                )
              : r,
      ]);

    reportesEnviados += pendientes.length;
    return pendientes.length;
  }
}

/// Utilidades para crear reportes de prueba validos.
Reporte reporteDePrueba({
  String id = 'r_test_1',
  String codigo = 'EC-2026-AL',
  String titulo = 'Titulo de prueba valido',
  String detalle = 'Detalle de prueba con mas de diez caracteres.',
  String categoria = 'Carga',
  int prioridad = 3,
  bool sincronizado = false,
}) {
  return Reporte(
    id: id,
    codigo: codigo,
    titulo: titulo,
    detalle: detalle,
    categoria: categoria,
    prioridad: prioridad,
    registradoEn: DateTime(2026, 11, 25, 8, 30),
    sincronizado: sincronizado,
  );
}
