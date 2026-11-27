import 'package:flutter/foundation.dart';

import '../../configuracion.dart';
import '../../domain/entities/zona.dart';
import '../../domain/repositories/repositorio_reportes.dart';

/// Modulo 2.3 - Estado desacoplado del catalogo bidimensional.
///
/// Encapsula las zonas del `GridView`, el filtro de riesgo y la sincronizacion
/// con la nube. La vista solo escucha con `ListenableBuilder`.
class CatalogoController extends ChangeNotifier {
  CatalogoController({required RepositorioReportes repositorio})
      : _repositorio = repositorio;

  final RepositorioReportes _repositorio;

  List<Zona> _zonas = const [];
  int? _riesgoActivo;
  bool _cargando = false;
  bool _sincronizando = false;
  String? _estadoRed;

  List<Zona> get zonas => _zonas;
  int? get riesgoActivo => _riesgoActivo;
  bool get cargando => _cargando;
  bool get sincronizando => _sincronizando;
  String? get estadoRed => _estadoRed;

  /// Zonas visibles segun el filtro de riesgo activo.
  List<Zona> get zonasFiltradas => _riesgoActivo == null
      ? _zonas
      : _zonas.where((z) => z.riesgo == _riesgoActivo).toList();

  int get totalAtencion => _zonas.where((z) => z.requiereAtencion).length;

  /// Carga el catalogo local (SQLite) - responde aunque no haya internet.
  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      _zonas = await _repositorio.obtenerZonas();
    } catch (_) {
      _estadoRed = 'No se pudo leer el catalogo local';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> aplicarFiltroDeRiesgo(int? riesgo) async {
    _riesgoActivo = riesgo;
    notifyListeners();
  }

  /// Sincroniza con la API REST **y** envia la cola de reportes pendientes.
  ///
  /// Si la red falla, la excepcion capturada deja **intactos** los datos
  /// locales (Offline-First) y solo actualiza el mensaje de estado.
  ///
  /// Zonas y reportes se intentan por separado: un fallo en el catalogo no
  /// debe impedir subir los reportes ya capturados, ni viceversa.
  Future<void> sincronizar() async {
    if (_sincronizando) return;
    _sincronizando = true;
    _estadoRed = 'Sincronizando con la nube...';
    notifyListeners();

    var zonasActualizadas = 0;
    var reportesEnviados = 0;
    var falloZonas = false;
    var falloReportes = false;

    try {
      final zonas = await _repositorio.descargarZonas(
        token: AppConfig.tokenJwt,
      );
      await _repositorio.guardarZonas(zonas);
      _zonas = await _repositorio.obtenerZonas();
      zonasActualizadas = zonas.length;
    } catch (_) {
      falloZonas = true;
    }

    try {
      reportesEnviados = await _repositorio.sincronizarReportesPendientes(
        token: AppConfig.tokenJwt,
      );
    } catch (_) {
      falloReportes = true;
    }

    if (falloZonas && falloReportes) {
      _estadoRed =
          'Sin conexion: catalogo local intacto (${_zonas.length} zonas)';
    } else if (falloReportes) {
      _estadoRed = 'Catalogo: $zonasActualizadas zonas. '
          'La cola de reportes sigue pendiente (se reintentara).';
    } else if (falloZonas) {
      _estadoRed = 'Cola enviada: $reportesEnviados reportes. '
          'El catalogo de zonas no se pudo actualizar.';
    } else {
      _estadoRed = 'Sincronizado: $zonasActualizadas zonas y '
          '$reportesEnviados reportes enviados';
    }

    _sincronizando = false;
    notifyListeners();
  }

  void limpiarEstadoRed() {
    if (_estadoRed == null) return;
    _estadoRed = null;
    notifyListeners();
  }

  /// Sin temporizadores ni listeners propios: `dispose` solo libera al
  /// `ChangeNotifier` (sin fugas de memoria).
  @override
  void dispose() {
    super.dispose();
  }
}
