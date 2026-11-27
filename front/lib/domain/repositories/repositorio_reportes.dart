import '../entities/reporte.dart';
import '../entities/zona.dart';

/// Puerto del dominio. Hoy lo implementa un repositorio en memoria; cuando se
/// conecte el backend (SQLite + API REST) solo se cambia la implementacion.
abstract class RepositorioReportes {
  Future<List<Reporte>> obtenerReportes();
  Future<void> guardarReporte(Reporte reporte);
  Future<void> eliminarReporte(String id);
  Future<List<Reporte>> sincronizarPendientes();
  Future<List<Zona>> obtenerZonas();
}
