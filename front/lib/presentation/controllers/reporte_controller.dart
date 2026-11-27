import 'package:flutter/foundation.dart';

import '../../domain/entities/reporte.dart';
import '../../domain/repositories/repositorio_reportes.dart';

/// Estado desacoplado del panel de reportes (`ChangeNotifier`).
class ReporteController extends ChangeNotifier {
  ReporteController({required RepositorioReportes repositorio})
    : _repositorio = repositorio;

  final RepositorioReportes _repositorio;

  List<Reporte> _reportes = const [];
  String? _categoriaActiva;
  bool _cargando = false;
  bool _sincronizando = false;
  String? _mensaje;

  List<Reporte> get reportes => _reportes;
  String? get categoriaActiva => _categoriaActiva;
  bool get cargando => _cargando;
  bool get sincronizando => _sincronizando;
  String? get mensaje => _mensaje;

  /// Reportes visibles segun el filtro, los criticos primero y luego los
  /// mas recientes.
  List<Reporte> get reportesFiltrados {
    final lista = _categoriaActiva == null
        ? [..._reportes]
        : _reportes.where((r) => r.categoria == _categoriaActiva).toList();
    lista.sort((a, b) {
      if (a.esCritico != b.esCritico) return a.esCritico ? -1 : 1;
      return b.registradoEn.compareTo(a.registradoEn);
    });
    return lista;
  }

  int get total => _reportes.length;
  int get totalCriticos => _reportes.where((r) => r.esCritico).length;
  int get totalPendientes =>
      _reportes.where((r) => r.pendienteDeSincronizar).length;

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      _reportes = await _repositorio.obtenerReportes();
    } catch (_) {
      _mensaje = 'No se pudieron cargar los reportes';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void filtrarPorCategoria(String? categoria) {
    if (_categoriaActiva == categoria) return;
    _categoriaActiva = categoria;
    notifyListeners();
  }

  Future<void> agregar(Reporte reporte) async {
    await _repositorio.guardarReporte(reporte);
    _reportes = await _repositorio.obtenerReportes();
    notifyListeners();
  }

  Future<void> eliminar(String id) async {
    await _repositorio.eliminarReporte(id);
    _reportes = await _repositorio.obtenerReportes();
    _mensaje = 'Reporte eliminado';
    notifyListeners();
  }

  Future<void> sincronizar() async {
    if (_sincronizando) return;
    final pendientes = totalPendientes;
    _sincronizando = true;
    _mensaje = null;
    notifyListeners();
    try {
      _reportes = await _repositorio.sincronizarPendientes();
      _mensaje = pendientes == 0
          ? 'Todo esta al dia: no hay reportes pendientes'
          : 'Sincronizados $pendientes reportes pendientes';
    } catch (_) {
      _mensaje = 'Sin conexion: los reportes siguen guardados localmente';
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  void limpiarMensaje() {
    if (_mensaje == null) return;
    _mensaje = null;
    notifyListeners();
  }
}
