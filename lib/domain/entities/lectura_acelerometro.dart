/// Modulo 4.1 - Lectura inmutable del acelerometro.
///
/// Vive en `domain` (sin Flutter, sin plugins) para que la regla de deteccion
/// pueda probarse unitariamente y la vista nunca conozca `sensors_plus`.
class LecturaAcelerometro {
  const LecturaAcelerometro({
    required this.x,
    required this.y,
    required this.z,
  });

  /// Aceleracion instantanea en m/s^2 para cada eje.
  final double x;
  final double y;
  final double z;

  /// Valor absoluto mas alto de los tres ejes.
  double get magnitudMaxima => [x.abs(), y.abs(), z.abs()].reduce(
        (a, b) => a > b ? a : b,
      );

  @override
  String toString() =>
      'LecturaAcelerometro(x: $x, y: $y, z: $z)';
}
