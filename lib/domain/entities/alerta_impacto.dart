/// Modulo 4.1 - Evento de impacto/emergencia detectado en ruta.
///
/// Entidad inmutable: solo describe que ocurrio, sin reproducir sonido ni
/// mostrar interfaz (esas responsabilidades estan en `data` y `presentation`).
class AlertaImpacto {
  const AlertaImpacto({
    required this.eje,
    required this.magnitud,
    required this.detectadoEn,
    this.simulada = false,
  });

  /// Eje que supero el umbral: 'X', 'Y' o 'Z'.
  final String eje;

  /// Aceleracion absoluta medida en m/s^2.
  final double magnitud;

  final DateTime detectadoEn;

  /// `true` cuando la alerta se disparo con el boton de simulacion manual.
  final bool simulada;

  String get origen => simulada ? 'Simulacion manual' : 'Acelerometro';

  String get magnitudFormateada => magnitud.toStringAsFixed(1);

  @override
  String toString() =>
      'AlertaImpacto(eje: $eje, magnitud: $magnitudFormateada, '
      'simulada: $simulada)';
}
