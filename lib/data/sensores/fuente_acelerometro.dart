import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/lectura_acelerometro.dart';

/// Modulo 4.1 - Adaptador de `sensors_plus` hacia el dominio.
///
/// Unico lugar de la app que importa el plugin del acelerometro. Expone un
/// `Stream` continuo de lecturas desacopladas de `AccelerometerEvent`.
class FuenteAcelerometro {
  /// Flujo continuo de aceleracion (m/s^2), incluido el eje Z.
  Stream<LecturaAcelerometro> lecturas() => accelerometerEventStream().map(
        (evento) => LecturaAcelerometro(
          x: evento.x,
          y: evento.y,
          z: evento.z,
        ),
      );
}
