import '../entities/alerta_impacto.dart';
import '../entities/lectura_acelerometro.dart';

/// Modulo 4.1 - Regla de negocio de la "Alerta de Impacto o Emergencia".
///
/// La logica del umbral NO se escribe en `build`: se concentra aqui, en
/// `domain`, para poder probarla sin dispositivo ni widgets.
class DetectorImpacto {
  const DetectorImpacto._();

  /// Umbral de seguridad en m/s^2 (cualquiera de los ejes X, Y o Z).
  static const double umbral = 15.0;

  /// Devuelve una [AlertaImpacto] cuando algun eje supera [umbral].
  ///
  /// Se usa el valor absoluto porque un golpe tambien puede registrar
  /// aceleracion negativa segun la orientacion del dispositivo.
  static AlertaImpacto? evaluar(
    LecturaAcelerometro lectura, {
    DateTime? momento,
  }) {
    final ejes = <String, double>{
      'X': lectura.x,
      'Y': lectura.y,
      'Z': lectura.z,
    };

    for (final MapEntry(:key, :value) in ejes.entries) {
      final magnitud = value.abs();
      if (magnitud > umbral) {
        return AlertaImpacto(
          eje: key,
          magnitud: magnitud,
          detectadoEn: momento ?? DateTime.now(),
        );
      }
    }
    return null;
  }

  /// Construye la alerta usada por el boton de simulacion manual.
  static AlertaImpacto simular({DateTime? momento}) => AlertaImpacto(
        eje: 'X',
        magnitud: umbral + 1.0,
        detectadoEn: momento ?? DateTime.now(),
        simulada: true,
      );
}
