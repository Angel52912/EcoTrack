import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/alerta_impacto.dart';
import '../../domain/entities/lectura_acelerometro.dart';
import '../../domain/repositories/servicio_alertas.dart';
import '../../domain/validadores/detector_impacto.dart';

/// Modulo 4 - Estado observable de la alerta de impacto.
///
/// Concentra la suscripcion al `Stream` del acelerometro, el cooldown, el
/// aviso visual y la liberacion de recursos. No importa ningun plugin: la
/// lectura llega como [LecturaAcelerometro] y los efectos como [ServicioAlertas].
class AlertaController extends ChangeNotifier {
  AlertaController({
    required ServicioAlertas servicio,
    required Stream<LecturaAcelerometro> acelerometro,
    this.cooldown = const Duration(seconds: 5),
    this.duracionAlerta = const Duration(seconds: 8),
  })  : _servicio = servicio,
        _acelerometro = acelerometro;

  /// Variante sin plugins, util para pruebas de widget y vistas aisladas.
  factory AlertaController.sinServicio() => AlertaController(
        servicio: const _ServicioAlertasNulo(),
        acelerometro: const Stream<LecturaAcelerometro>.empty(),
      );

  final ServicioAlertas _servicio;
  final Stream<LecturaAcelerometro> _acelerometro;

  /// Tiempo minimo entre dos disparos (evita repetir el audio y la notificacion).
  final Duration cooldown;

  /// Cuanto tiempo permanece visible el banner de emergencia.
  final Duration duracionAlerta;

  StreamSubscription<LecturaAcelerometro>? _suscripcion;
  Timer? _temporizador;
  AlertaImpacto? _alerta;
  DateTime? _ultimoDisparo;
  int _totalAlertas = 0;
  bool _monitoreando = false;
  bool _dispuesto = false;

  // ---------------------------------------------------------------------------
  // Estado observable (solo lectura para la vista)
  // ---------------------------------------------------------------------------
  bool get monitoreando => _monitoreando && !_dispuesto;
  AlertaImpacto? get alerta => _alerta;
  bool get alertaActiva => _alerta != null;
  int get totalAlertas => _totalAlertas;
  int get umbral => DetectorImpacto.umbral.toInt();

  /// `true` mientras no ha pasado [cooldown] desde el ultimo disparo.
  bool get enEnfriamiento {
    if (_ultimoDisparo == null) return false;
    return DateTime.now().difference(_ultimoDisparo!) < cooldown;
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Se invoca desde `initState()` de la vista: aqui se escucha el Stream
  /// continuo del acelerometro (no dentro de `build`).
  void iniciarMonitoreo() {
    if (_dispuesto || _suscripcion != null) return;
    _monitoreando = true;
    _suscripcion = _acelerometro.listen(
      _procesarLectura,
      onError: (Object _) {
        // Un sensor no disponible no debe derribar la interfaz.
      },
    );
    notifyListeners();
  }

  void _procesarLectura(LecturaAcelerometro lectura) {
    final detectada = DetectorImpacto.evaluar(lectura);
    if (detectada != null) disparar(detectada);
  }

  /// Boton de simulacion manual (mismo flujo que una lectura real).
  Future<void> simularAlerta() => disparar(DetectorImpacto.simular());

  /// Dispara la alerta visual, el audio local y la notificacion prioritaria.
  Future<void> disparar(AlertaImpacto impacto) async {
    if (_dispuesto) return;

    final ahora = DateTime.now();
    if (_ultimoDisparo != null &&
        ahora.difference(_ultimoDisparo!) < cooldown) {
      return; // Cooldown: se ignora el evento para no saturar sonido/avisos.
    }

    _ultimoDisparo = ahora;
    _alerta = impacto;
    _totalAlertas++;
    _temporizador?.cancel();
    _temporizador = Timer(duracionAlerta, limpiarAlerta);
    notifyListeners();

    try {
      await _servicio.reproducirAlerta();
      await _servicio.notificarEmergencia(impacto);
    } catch (_) {
      // Si el dispositivo no tiene plugin (emulador/pruebas), la alerta visual
      // sigue funcionando y no se propaga un error no capturado.
    }
  }

  /// Notificacion de alta prioridad al confirmar un envio en el formulario.
  Future<void> confirmarEnvio(String codigo) async {
    if (_dispuesto) return;
    try {
      await _servicio.notificarEnvioConfirmado(codigo);
    } catch (_) {
      // La persistencia local ya ocurrio: un fallo del plugin no la revierte.
    }
  }

  void limpiarAlerta() {
    if (_alerta == null) return;
    _alerta = null;
    _temporizador?.cancel();
    _temporizador = null;
    if (!_dispuesto) notifyListeners();
  }

  /// Modulo 4.4: cancela la suscripcion, el temporizador y el reproductor.
  @override
  void dispose() {
    if (_dispuesto) return;
    _dispuesto = true;
    _suscripcion?.cancel();
    _suscripcion = null;
    _temporizador?.cancel();
    _temporizador = null;
    _servicio.liberar();
    super.dispose();
  }
}

/// Adaptador vacio: permite construir la vista sin canales nativos.
class _ServicioAlertasNulo implements ServicioAlertas {
  const _ServicioAlertasNulo();

  @override
  Future<void> inicializar() async {}

  @override
  Future<void> reproducirAlerta() async {}

  @override
  Future<void> notificarEmergencia(AlertaImpacto alerta) async {}

  @override
  Future<void> notificarEnvioConfirmado(String codigo) async {}

  @override
  void liberar() {}
}
