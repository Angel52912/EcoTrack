import '../entities/reporte.dart';
import '../entities/zona.dart';

/// Modulo 1 - Capa `domain`.
///
/// Puerto (interfaz) que define lo que el negocio necesita persistir o
/// descargar. La implementacion concreta vive en `data/`, de modo que el
/// dominio no conoce SQLite, HTTP ni ningun detalle de infraestructura.
abstract interface class RepositorioReportes {
  /// Lee reportes locales. Cuando [categoria] no es nula la consulta se
  /// filtra con parametros posicionales (`whereArgs`).
  Future<List<Reporte>> obtenerReportes({String? categoria});

  /// Persiste un reporte capturado en campo (estrategia Offline-First:
  /// primero local, luego la nube).
  Future<void> guardarReporte(Reporte reporte);

  /// Elimina un reporte local por su identificador.
  Future<void> eliminarReporte(String id);

  /// Lee el catalogo de zonas desde el almacenamiento local.
  Future<List<Zona>> obtenerZonas();

  /// Reemplaza el catalogo local con los datos provenientes de la nube.
  Future<void> guardarZonas(List<Zona> zonas);

  /// Descarga el catalogo desde la API REST. **Propaga cualquier excepcion
  /// de red** (el llamador decide que hacer: la capa de presentacion
  /// conserva los datos locales y solo informa "sin conexion").
  Future<List<Zona>> descargarZonas({required String token});
}
