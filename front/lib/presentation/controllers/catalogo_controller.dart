import 'package:flutter/foundation.dart';

import '../../domain/entities/zona.dart';
import '../../domain/repositories/repositorio_reportes.dart';

/// Estado desacoplado del catalogo de zonas (`GridView`).
class CatalogoController extends ChangeNotifier {
  CatalogoController({required RepositorioReportes repositorio})
    : _repositorio = repositorio;

  final RepositorioReportes _repositorio;

  List<Zona> _zonas = const [];
  int? _riesgoActivo;
  bool _cargando = false;

  List<Zona> get zonas => _zonas;
  int? get riesgoActivo => _riesgoActivo;
  bool get cargando => _cargando;

  List<Zona> get zonasFiltradas => _riesgoActivo == null
      ? _zonas
      : _zonas.where((z) => z.riesgo == _riesgoActivo).toList();

  int get totalAtencion => _zonas.where((z) => z.requiereAtencion).length;

  int get totalEntregas =>
      _zonas.fold(0, (suma, z) => suma + z.entregasPendientes);

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      _zonas = await _repositorio.obtenerZonas();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void filtrarPorRiesgo(int? riesgo) {
    if (_riesgoActivo == riesgo) return;
    _riesgoActivo = riesgo;
    notifyListeners();
  }
}
