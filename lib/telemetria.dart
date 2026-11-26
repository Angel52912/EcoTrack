import 'package:flutter/foundation.dart';

/// Modulo 5.2 - Telemetria de errores.
///
/// Recolector en memoria de los fallos globales capturados por
/// `FlutterError.onError` y `PlatformDispatcher.instance.onError` (configurados
/// en `main.dart`). En produccion esta lista se enviaria a un servicio de
/// monitoreo (Firebase Crashlytics, Sentry, etc.).
class Telemetria {
  Telemetria._();

  /// Maximo de eventos retenidos en memoria.
  static const int limiteDeEventos = 50;

  static final List<Map<String, Object?>> _errores = [];

  /// Copia inmutable de los eventos capturados.
  static List<Map<String, Object?>> get errores =>
      List.unmodifiable(_errores);

  static int get total => _errores.length;

  /// Registra un error con su origen, mensaje y traza.
  static void registrar({
    required String origen,
    required Object error,
    StackTrace? pila,
  }) {
    _errores.insert(0, {
      'origen': origen,
      'error': error.toString(),
      'pila': pila?.toString() ?? 'sin traza',
      'fecha': DateTime.now().toIso8601String(),
    });

    if (_errores.length > limiteDeEventos) {
      _errores.removeLast();
    }

    debugPrint('[Telemetria][$origen] $error');
  }

  /// Util para pruebas: limpia el historial.
  static void limpiar() => _errores.clear();
}
