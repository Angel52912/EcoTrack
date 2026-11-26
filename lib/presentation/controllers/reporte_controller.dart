import 'package:flutter/foundation.dart';

import '../../domain/entities/reporte.dart';
import '../../domain/repositories/repositorio_reportes.dart';

/// Modulo 2.3 - Estado desacoplado.
///
/// `ChangeNotifier` puro: concentra la logica observable del panel y avisa a
/// la vista con `notifyListeners()`. No importa ningun widget de Flutter, de
/// modo que puede probarse unitariamente con un repositorio falso.
class ReporteController extends ChangeNotifier {
  ReporteController({required RepositorioReportes repositorio})
      : _repositorio = repositorio;

  final RepositorioReportes _repositorio;

  List<Reporte> _reportes = const [];
  String? _categoriaActiva;
  bool _cargando = false;
  String? _error;
  String? _estadoRed;

  // ---------------------------------------------------------------------------
  // Estado observable (solo lectura para la vista).
  // ---------------------------------------------------------------------------
  List<Reporte> get reportes => _reportes;
  String? get categoriaActiva => _categoriaActiva;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Mensaje de sincronizacion ("con conexion" / "sin conexion").
  String? get estadoRed => _estadoRed;

  int get total => _reportes.length;
  int get totalCriticos => _reportes.where((r) => r.esCritico).length;
  int get pendientesDeSincronizar =>
      _reportes.where((r) => r.pendienteDeSincronizar).length;

  /// Categorias usadas por la barra de filtros `Wrap` de la vista.
  List<String> get categoriasDisponibles =>
      const ['Ruta', 'Carga', 'Seguridad', 'Ambiental'];

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Carga desde SQLite. Si [categoria] esta activa la consulta viaja a la
  /// base con `whereArgs` (sin concatenar SQL).
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _reportes = await _repositorio.obtenerReportes(
        categoria: _categoriaActiva,
      );
      _error = null;
    } catch (excepcion) {
      // Offline-First: ante un fallo local se conserva la lista en memoria.
      _error = 'No se pudieron leer los reportes locales: $excepcion';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Aplica el filtro elegido en la barra `Wrap` y recarga la consulta.
  Future<void> aplicarFiltro(String? categoria) async {
    _categoriaActiva = categoria;
    notifyListeners();
    await cargar();
  }

  /// Persiste un reporte nuevo y recarga el listado.
  Future<bool> agregar(Reporte reporte) async {
    try {
      await _repositorio.guardarReporte(reporte);
      await cargar();
      return true;
    } catch (excepcion) {
      _error = 'No se pudo guardar el reporte: $excepcion';
      notifyListeners();
      return false;
    }
  }

  Future<void> eliminar(String id) async {
    try {
      await _repositorio.eliminarReporte(id);
      await cargar();
    } catch (excepcion) {
      _error = 'No se pudo eliminar el reporte: $excepcion';
      notifyListeners();
    }
  }

  /// Limpia el mensaje informativo de red/estado.
  void limpiarEstadoRed() {
    if (_estadoRed == null) return;
    _estadoRed = null;
    notifyListeners();
  }

  /// El `dispose()` libera el recurso del `ChangeNotifier`; este controlador
  /// no crea temporizadores, streams ni suscripciones, por lo que no hay
  /// fugas de memoria que cerrar aqui.
  @override
  void dispose() {
    super.dispose();
  }
}
