import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/zona.dart';

/// Escenas disponibles. Las de zona salen de [TipoLugar]; las de reporte, de
/// su categoria.
enum Escena {
  centro,
  industrial,
  parque,
  vialidad,
  mercado,
  residencial,
  puerto,
  aeropuerto,
  universidad,
  bache,
  carga,
  callesNoche,
  reciclaje;

  static Escena deLugar(TipoLugar lugar) => switch (lugar) {
    TipoLugar.centro => Escena.centro,
    TipoLugar.industrial => Escena.industrial,
    TipoLugar.parque => Escena.parque,
    TipoLugar.vialidad => Escena.vialidad,
    TipoLugar.mercado => Escena.mercado,
    TipoLugar.residencial => Escena.residencial,
    TipoLugar.puerto => Escena.puerto,
    TipoLugar.aeropuerto => Escena.aeropuerto,
    TipoLugar.universidad => Escena.universidad,
  };

  static Escena deCategoria(String categoria) => switch (categoria) {
    'Carga' => Escena.carga,
    'Seguridad' => Escena.callesNoche,
    'Ambiental' => Escena.reciclaje,
    _ => Escena.bache,
  };

  /// Texto alternativo para lectores de pantalla.
  String get descripcion => switch (this) {
    Escena.centro => 'Centro historico con catedral y edificios coloniales',
    Escena.industrial => 'Zona industrial con fabrica, chimeneas y camion',
    Escena.parque => 'Parque con arboles, sendero y banca',
    Escena.vialidad => 'Via rapida con autos y senal de precaucion',
    Escena.mercado => 'Mercado con puestos de frutas y toldos',
    Escena.residencial => 'Colonia residencial con casas y arboles',
    Escena.puerto => 'Puerto con barco de contenedores y grua',
    Escena.aeropuerto => 'Aeropuerto con avion, pista y torre de control',
    Escena.universidad => 'Edificio universitario con columnas y bandera',
    Escena.bache => 'Carretera con un bache y un cono de precaucion',
    Escena.carga => 'Camion de reparto con cajas caidas',
    Escena.callesNoche => 'Calle de noche con una farola apagada',
    Escena.reciclaje => 'Contenedores de reciclaje junto a un arbol',
  };
}

/// Imagen ilustrada de una escena. Se recorta como `BoxFit.cover`.
class Ilustracion extends StatelessWidget {
  const Ilustracion({super.key, required this.escena, this.radio = 12});

  final Escena escena;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: escena.descripcion,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radio),
        child: CustomPaint(
          painter: PintorEscena(escena),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Dibuja las escenas sobre un lienzo virtual de 160 x 100.
class PintorEscena extends CustomPainter {
  PintorEscena(this.escena);

  final Escena escena;

  static const double _w = 160;
  static const double _h = 100;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final escala = math.max(size.width / _w, size.height / _h);
    canvas
      ..save()
      ..translate(
        (size.width - _w * escala) / 2,
        (size.height - _h * escala) / 2,
      )
      ..scale(escala);
    switch (escena) {
      case Escena.centro:
        _centro(canvas);
      case Escena.industrial:
        _industrial(canvas);
      case Escena.parque:
        _parque(canvas);
      case Escena.vialidad:
        _vialidad(canvas);
      case Escena.mercado:
        _mercado(canvas);
      case Escena.residencial:
        _residencial(canvas);
      case Escena.puerto:
        _puerto(canvas);
      case Escena.aeropuerto:
        _aeropuerto(canvas);
      case Escena.universidad:
        _universidad(canvas);
      case Escena.bache:
        _bache(canvas);
      case Escena.carga:
        _carga(canvas);
      case Escena.callesNoche:
        _callesNoche(canvas);
      case Escena.reciclaje:
        _reciclaje(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorEscena oldDelegate) => oldDelegate.escena != escena;

  // ---------------------------------------------------------------------------
  // Utilidades de dibujo
  // ---------------------------------------------------------------------------
  static Paint _p(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  static Paint _trazo(Color c, double ancho) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = ancho
    ..strokeCap = StrokeCap.round;

  static void _cielo(Canvas c, Color arriba, Color abajo) {
    c.drawRect(
      const Rect.fromLTWH(0, 0, _w, _h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [arriba, abajo],
        ).createShader(const Rect.fromLTWH(0, 0, _w, _h)),
    );
  }

  static void _cieloDia(Canvas c) =>
      _cielo(c, const Color(0xFF64B5F6), const Color(0xFFE3F2FD));

  static void _sol(Canvas c, Offset centro, [double r = 9]) {
    c.drawCircle(centro, r + 4, _p(const Color(0x55FFF59D)));
    c.drawCircle(centro, r, _p(const Color(0xFFFFD54F)));
  }

  static void _nube(Canvas c, Offset o, [double s = 1]) {
    final p = _p(const Color(0xF2FFFFFF));
    c.drawCircle(o, 5 * s, p);
    c.drawCircle(o + const Offset(6, -3) * s, 6 * s, p);
    c.drawCircle(o + const Offset(12, 0) * s, 5 * s, p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx - 4 * s, o.dy - 1 * s, 20 * s, 6 * s),
        Radius.circular(3 * s),
      ),
      p,
    );
  }

  static void _suelo(Canvas c, double y, Color color) =>
      c.drawRect(Rect.fromLTWH(0, y, _w, _h - y), _p(color));

  static void _arbol(
    Canvas c,
    double x,
    double base,
    double alto, [
    Color copa = const Color(0xFF43A047),
  ]) {
    c.drawRect(
      Rect.fromLTWH(x - 1.5, base - alto * 0.45, 3, alto * 0.45),
      _p(const Color(0xFF6D4C41)),
    );
    final r = alto * 0.32;
    c.drawCircle(Offset(x, base - alto * 0.62), r, _p(copa));
    c.drawCircle(Offset(x - r * 0.55, base - alto * 0.5), r * 0.75, _p(copa));
    c.drawCircle(Offset(x + r * 0.55, base - alto * 0.5), r * 0.75, _p(copa));
    c.drawCircle(
      Offset(x - r * 0.2, base - alto * 0.72),
      r * 0.45,
      _p(Colors.white.withValues(alpha: 0.12)),
    );
  }

  static void _ventanas(Canvas c, Rect r, int filas, int cols, Color color) {
    final aw = r.width / (cols * 2 + 1);
    final ah = r.height / (filas * 2 + 1);
    for (var i = 0; i < filas; i++) {
      for (var j = 0; j < cols; j++) {
        c.drawRect(
          Rect.fromLTWH(
            r.left + aw * (j * 2 + 1),
            r.top + ah * (i * 2 + 1),
            aw,
            ah,
          ),
          _p(color),
        );
      }
    }
  }

  static void _auto(Canvas c, Offset o, Color color, [double s = 1]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy - 5 * s, 18 * s, 5 * s),
        Radius.circular(1.5 * s),
      ),
      _p(color),
    );
    final techo = Path()
      ..moveTo(o.dx + 4 * s, o.dy - 5 * s)
      ..lineTo(o.dx + 6.5 * s, o.dy - 9 * s)
      ..lineTo(o.dx + 13 * s, o.dy - 9 * s)
      ..lineTo(o.dx + 15 * s, o.dy - 5 * s)
      ..close();
    c.drawPath(techo, _p(color));
    c.drawRect(
      Rect.fromLTWH(o.dx + 7 * s, o.dy - 8 * s, 5 * s, 2.5 * s),
      _p(const Color(0xFFB3E5FC)),
    );
    c.drawCircle(o + Offset(4.5 * s, 0), 2 * s, _p(const Color(0xFF263238)));
    c.drawCircle(o + Offset(13.5 * s, 0), 2 * s, _p(const Color(0xFF263238)));
  }

  static void _camion(
    Canvas c,
    Offset o, {
    Color caja = const Color(0xFF2E7D32),
    bool abierto = false,
  }) {
    // Caja de carga
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy - 20, 32, 17),
        const Radius.circular(1.5),
      ),
      _p(caja),
    );
    if (abierto) {
      c.drawRect(
        Rect.fromLTWH(o.dx + 29, o.dy - 18, 3, 13),
        _p(const Color(0xFF1B1B1B)),
      );
    } else {
      // Hoja ecologica en la caja
      final hoja = Path()
        ..moveTo(o.dx + 12, o.dy - 8)
        ..quadraticBezierTo(o.dx + 12, o.dy - 17, o.dx + 21, o.dy - 16)
        ..quadraticBezierTo(o.dx + 21, o.dy - 8, o.dx + 12, o.dy - 8)
        ..close();
      c.drawPath(hoja, _p(Colors.white.withValues(alpha: 0.85)));
    }
    // Cabina
    final cabina = Path()
      ..moveTo(o.dx - 1, o.dy - 3)
      ..lineTo(o.dx - 1, o.dy - 14)
      ..lineTo(o.dx - 8, o.dy - 14)
      ..lineTo(o.dx - 12, o.dy - 8)
      ..lineTo(o.dx - 12, o.dy - 3)
      ..close();
    c.drawPath(cabina, _p(const Color(0xFFECEFF1)));
    c.drawRect(
      Rect.fromLTWH(o.dx - 8.5, o.dy - 12.5, 6, 4),
      _p(const Color(0xFF81D4FA)),
    );
    for (final x in [o.dx - 7, o.dx + 8, o.dx + 24]) {
      c.drawCircle(Offset(x, o.dy - 2), 3.2, _p(const Color(0xFF263238)));
      c.drawCircle(Offset(x, o.dy - 2), 1.3, _p(const Color(0xFF90A4AE)));
    }
  }

  static void _caja(Canvas c, Rect r, [double giro = 0]) {
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.rotate(giro);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: r.width,
      height: r.height,
    );
    c.drawRect(local, _p(const Color(0xFFD7A86E)));
    c.drawRect(local, _trazo(const Color(0xFF8D6E63), 0.6));
    c.drawLine(
      local.topCenter,
      local.bottomCenter,
      _trazo(const Color(0xFFB0855A), 1.2),
    );
    c.restore();
  }

  // ---------------------------------------------------------------------------
  // Escenas de zonas
  // ---------------------------------------------------------------------------
  void _centro(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(138, 18));
    _nube(c, const Offset(20, 16));
    // Catedral
    const piedra = Color(0xFFE0C9A6);
    const sombra = Color(0xFFC9AE86);
    c.drawRect(const Rect.fromLTWH(58, 40, 44, 42), _p(piedra));
    for (final x in [52.0, 96.0]) {
      c.drawRect(Rect.fromLTWH(x, 24, 12, 58), _p(sombra));
      final cupula = Path()
        ..moveTo(x, 24)
        ..lineTo(x + 6, 14)
        ..lineTo(x + 12, 24)
        ..close();
      c.drawPath(cupula, _p(const Color(0xFFA1887F)));
      c.drawLine(
        Offset(x + 6, 14),
        Offset(x + 6, 9),
        _trazo(const Color(0xFF5D4037), 0.8),
      );
      c.drawLine(
        Offset(x + 4, 11),
        Offset(x + 8, 11),
        _trazo(const Color(0xFF5D4037), 0.8),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 4, 30, 4, 7),
          const Radius.circular(2),
        ),
        _p(const Color(0xFF6D4C41)),
      );
    }
    final frontis = Path()
      ..moveTo(58, 40)
      ..lineTo(80, 28)
      ..lineTo(102, 40)
      ..close();
    c.drawPath(frontis, _p(sombra));
    c.drawCircle(const Offset(80, 36), 3, _p(const Color(0xFF8D6E63)));
    c.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(73, 60, 14, 22),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      ),
      _p(const Color(0xFF5D4037)),
    );
    // Casas coloniales con arcos
    const colores = [
      Color(0xFFF48FB1),
      Color(0xFFFFCC80),
      Color(0xFF80CBC4),
      Color(0xFFCE93D8),
    ];
    final xs = [0.0, 24.0, 112.0, 136.0];
    for (var i = 0; i < 4; i++) {
      final r = Rect.fromLTWH(xs[i], 56, 24, 26);
      c.drawRect(r, _p(colores[i]));
      c.drawRect(
        Rect.fromLTWH(r.left, 54, 24, 3),
        _p(colores[i].withValues(alpha: 0.7)),
      );
      for (var j = 0; j < 2; j++) {
        c.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(r.left + 3 + j * 11, 66, 7, 16),
            topLeft: const Radius.circular(3.5),
            topRight: const Radius.circular(3.5),
          ),
          _p(Colors.white.withValues(alpha: 0.75)),
        );
      }
    }
    _suelo(c, 82, const Color(0xFFBDBDBD));
    for (var x = 0.0; x < _w; x += 8) {
      c.drawLine(
        Offset(x, 82),
        Offset(x + 4, 100),
        _trazo(const Color(0x33000000), 0.5),
      );
    }
  }

  void _industrial(Canvas c) {
    _cielo(c, const Color(0xFF90A4AE), const Color(0xFFECEFF1));
    // Humo
    for (final o in [const Offset(30, 18), const Offset(48, 10)]) {
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
          o + Offset(i * 5.0, -i * 4.0),
          4.0 + i * 1.5,
          _p(Colors.white.withValues(alpha: 0.7 - i * 0.15)),
        );
      }
    }
    // Chimeneas
    c.drawRect(const Rect.fromLTWH(26, 22, 7, 38), _p(const Color(0xFF8D6E63)));
    c.drawRect(const Rect.fromLTWH(44, 14, 7, 46), _p(const Color(0xFF795548)));
    for (final x in [26.0, 44.0]) {
      c.drawRect(
        Rect.fromLTWH(x, x == 26 ? 28 : 20, 7, 2.5),
        _p(const Color(0xFFE53935)),
      );
    }
    // Nave con techo de diente de sierra
    const nave = Color(0xFF78909C);
    c.drawRect(const Rect.fromLTWH(14, 56, 110, 26), _p(nave));
    final sierra = Path()..moveTo(14, 56);
    for (var x = 14.0; x < 124; x += 22) {
      sierra
        ..lineTo(x, 44)
        ..lineTo(x + 22, 56);
    }
    sierra.close();
    c.drawPath(sierra, _p(const Color(0xFF607D8B)));
    _ventanas(
      c,
      const Rect.fromLTWH(14, 58, 110, 12),
      1,
      7,
      const Color(0xFFFFF59D),
    );
    c.drawRect(
      const Rect.fromLTWH(96, 68, 18, 14),
      _p(const Color(0xFF455A64)),
    );
    for (var y = 70.0; y < 82; y += 3) {
      c.drawLine(
        Offset(96, y),
        Offset(114, y),
        _trazo(const Color(0xFF37474F), 0.6),
      );
    }
    // Tanque
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(128, 50, 22, 32),
        const Radius.circular(10),
      ),
      _p(const Color(0xFFB0BEC5)),
    );
    _suelo(c, 82, const Color(0xFF616161));
    c.drawLine(
      const Offset(0, 91),
      const Offset(_w, 91),
      _trazo(const Color(0xFFFFEB3B), 1)..strokeCap = StrokeCap.butt,
    );
    _camion(c, const Offset(118, 96));
  }

  void _parque(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(28, 20));
    _nube(c, const Offset(100, 14), 1.1);
    // Colinas
    c.drawOval(
      const Rect.fromLTWH(-30, 50, 120, 60),
      _p(const Color(0xFF81C784)),
    );
    c.drawOval(
      const Rect.fromLTWH(60, 46, 140, 70),
      _p(const Color(0xFF66BB6A)),
    );
    _suelo(c, 72, const Color(0xFF4CAF50));
    // Sendero
    final sendero = Path()
      ..moveTo(70, 100)
      ..quadraticBezierTo(78, 84, 96, 76)
      ..lineTo(104, 76)
      ..quadraticBezierTo(92, 86, 96, 100)
      ..close();
    c.drawPath(sendero, _p(const Color(0xFFD7CCC8)));
    _arbol(c, 18, 82, 38, const Color(0xFF2E7D32));
    _arbol(c, 42, 78, 30);
    _arbol(c, 124, 80, 36, const Color(0xFF388E3C));
    _arbol(c, 148, 76, 28, const Color(0xFF66BB6A));
    // Banca
    c.drawRect(
      const Rect.fromLTWH(54, 80, 18, 2.5),
      _p(const Color(0xFF8D6E63)),
    );
    c.drawRect(const Rect.fromLTWH(54, 76, 18, 2), _p(const Color(0xFF8D6E63)));
    c.drawLine(
      const Offset(56, 82),
      const Offset(56, 87),
      _trazo(const Color(0xFF424242), 1),
    );
    c.drawLine(
      const Offset(70, 82),
      const Offset(70, 87),
      _trazo(const Color(0xFF424242), 1),
    );
    // Flores
    for (final f in [
      const Offset(30, 92),
      const Offset(112, 90),
      const Offset(138, 94),
      const Offset(10, 96),
    ]) {
      c.drawCircle(f, 1.6, _p(const Color(0xFFFFEB3B)));
      c.drawCircle(f + const Offset(3, 1), 1.6, _p(const Color(0xFFF06292)));
    }
  }

  void _vialidad(Canvas c) {
    _cieloDia(c);
    _nube(c, const Offset(24, 14));
    _nube(c, const Offset(110, 20), 0.8);
    // Ciudad al fondo
    for (var i = 0; i < 9; i++) {
      final alto = 10.0 + (i * 7 % 13);
      c.drawRect(
        Rect.fromLTWH(i * 18.0, 46 - alto, 14, alto),
        _p(const Color(0xFFB0BEC5)),
      );
    }
    _suelo(c, 46, const Color(0xFF8BC34A));
    // Carretera en perspectiva
    final via = Path()
      ..moveTo(70, 46)
      ..lineTo(90, 46)
      ..lineTo(170, 100)
      ..lineTo(-10, 100)
      ..close();
    c.drawPath(via, _p(const Color(0xFF455A64)));
    for (var i = 0; i < 5; i++) {
      final t0 = i / 5;
      final t1 = t0 + 0.1;
      c.drawLine(
        Offset(80, 46 + 54 * t0),
        Offset(80, 46 + 54 * t1),
        _trazo(Colors.white, 0.8 + t0 * 2.5)..strokeCap = StrokeCap.butt,
      );
    }
    c.drawLine(
      const Offset(70, 46),
      const Offset(-10, 100),
      _trazo(const Color(0xFFFFEB3B), 1.5),
    );
    c.drawLine(
      const Offset(90, 46),
      const Offset(170, 100),
      _trazo(const Color(0xFFFFEB3B), 1.5),
    );
    _auto(c, const Offset(46, 90), const Color(0xFFE53935), 1.3);
    _auto(c, const Offset(86, 66), const Color(0xFF1E88E5), 0.8);
    // Senal de precaucion
    c.drawLine(
      const Offset(142, 80),
      const Offset(142, 54),
      _trazo(const Color(0xFF9E9E9E), 1.5),
    );
    final senal = Path()
      ..moveTo(142, 40)
      ..lineTo(152, 56)
      ..lineTo(132, 56)
      ..close();
    c.drawPath(senal, _p(const Color(0xFFFFC107)));
    c.drawPath(senal, _trazo(const Color(0xFF212121), 1));
    c.drawLine(
      const Offset(142, 46),
      const Offset(142, 51),
      _trazo(const Color(0xFF212121), 1.4),
    );
    c.drawCircle(const Offset(142, 53.5), 0.8, _p(const Color(0xFF212121)));
  }

  void _mercado(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(140, 16), 7);
    c.drawRect(const Rect.fromLTWH(0, 30, _w, 40), _p(const Color(0xFFFFE0B2)));
    _ventanas(
      c,
      const Rect.fromLTWH(0, 30, _w, 20),
      1,
      8,
      const Color(0xFFBCAAA4),
    );
    _suelo(c, 70, const Color(0xFFBCAAA4));
    const toldos = [Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5)];
    const frutas = [
      [Color(0xFFFF7043), Color(0xFFFFCA28)],
      [Color(0xFF66BB6A), Color(0xFFEF5350)],
      [Color(0xFFFFEE58), Color(0xFFAB47BC)],
    ];
    for (var i = 0; i < 3; i++) {
      final x = 6.0 + i * 52;
      // Postes
      c.drawLine(
        Offset(x + 2, 50),
        Offset(x + 2, 86),
        _trazo(const Color(0xFF6D4C41), 1.5),
      );
      c.drawLine(
        Offset(x + 44, 50),
        Offset(x + 44, 86),
        _trazo(const Color(0xFF6D4C41), 1.5),
      );
      // Toldo a rayas
      for (var j = 0; j < 6; j++) {
        c.drawRect(
          Rect.fromLTWH(x + j * 7.67, 42, 7.67, 10),
          _p(j.isEven ? toldos[i] : Colors.white),
        );
      }
      for (var j = 0; j < 6; j++) {
        c.drawCircle(
          Offset(x + 3.8 + j * 7.67, 52),
          3.8,
          _p(j.isEven ? toldos[i] : Colors.white),
        );
      }
      // Mostrador con fruta
      c.drawRect(Rect.fromLTWH(x, 72, 46, 14), _p(const Color(0xFFA1887F)));
      for (var k = 0; k < 7; k++) {
        c.drawCircle(Offset(x + 5 + k * 6, 70), 3, _p(frutas[i][k % 2]));
      }
      for (var k = 0; k < 6; k++) {
        c.drawCircle(Offset(x + 8 + k * 6, 66), 3, _p(frutas[i][(k + 1) % 2]));
      }
    }
    _caja(c, const Rect.fromLTWH(140, 88, 12, 9));
  }

  void _residencial(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(24, 18), 7);
    _nube(c, const Offset(110, 14));
    _suelo(c, 74, const Color(0xFF7CB342));
    c.drawRect(const Rect.fromLTWH(0, 86, _w, 14), _p(const Color(0xFF9E9E9E)));
    c.drawRect(const Rect.fromLTWH(0, 84, _w, 2), _p(const Color(0xFFE0E0E0)));
    const muros = [
      Color(0xFFFFF3E0),
      Color(0xFFE1F5FE),
      Color(0xFFFCE4EC),
      Color(0xFFF1F8E9),
    ];
    const techos = [
      Color(0xFFD84315),
      Color(0xFF5D4037),
      Color(0xFF00897B),
      Color(0xFFC62828),
    ];
    for (var i = 0; i < 4; i++) {
      final x = 6.0 + i * 40;
      final alto = i.isEven ? 26.0 : 22.0;
      final base = 82.0;
      c.drawRect(Rect.fromLTWH(x, base - alto, 28, alto), _p(muros[i]));
      final techo = Path()
        ..moveTo(x - 3, base - alto)
        ..lineTo(x + 14, base - alto - 14)
        ..lineTo(x + 31, base - alto)
        ..close();
      c.drawPath(techo, _p(techos[i]));
      c.drawRect(
        Rect.fromLTWH(x + 11, base - 12, 7, 12),
        _p(const Color(0xFF6D4C41)),
      );
      c.drawRect(
        Rect.fromLTWH(x + 3, base - alto + 5, 6, 6),
        _p(const Color(0xFF81D4FA)),
      );
      c.drawRect(
        Rect.fromLTWH(x + 20, base - alto + 5, 6, 6),
        _p(const Color(0xFF81D4FA)),
      );
      if (i < 3) {
        _arbol(
          c,
          x + 36,
          84,
          20,
          i.isEven ? const Color(0xFF388E3C) : const Color(0xFF43A047),
        );
      }
    }
  }

  void _puerto(Canvas c) {
    _cielo(c, const Color(0xFF4FC3F7), const Color(0xFFFFF8E1));
    _sol(c, const Offset(30, 30), 10);
    // Mar
    c.drawRect(const Rect.fromLTWH(0, 58, _w, 42), _p(const Color(0xFF0288D1)));
    for (var y = 64.0; y < 100; y += 7) {
      for (var x = (y % 14 == 0 ? 0.0 : 6.0); x < _w; x += 14) {
        c.drawLine(
          Offset(x, y),
          Offset(x + 5, y),
          _trazo(Colors.white.withValues(alpha: 0.5), 0.8),
        );
      }
    }
    // Muelle y grua
    c.drawRect(
      const Rect.fromLTWH(118, 54, 42, 8),
      _p(const Color(0xFF8D6E63)),
    );
    c.drawLine(
      const Offset(138, 54),
      const Offset(138, 18),
      _trazo(const Color(0xFFF9A825), 2.4),
    );
    c.drawLine(
      const Offset(148, 54),
      const Offset(148, 18),
      _trazo(const Color(0xFFF9A825), 2.4),
    );
    c.drawLine(
      const Offset(100, 18),
      const Offset(156, 18),
      _trazo(const Color(0xFFF9A825), 2.4),
    );
    c.drawLine(
      const Offset(110, 18),
      const Offset(110, 34),
      _trazo(const Color(0xFF424242), 0.7),
    );
    c.drawRect(
      const Rect.fromLTWH(105, 34, 10, 5),
      _p(const Color(0xFFE53935)),
    );
    // Barco de contenedores
    final casco = Path()
      ..moveTo(10, 60)
      ..lineTo(104, 60)
      ..lineTo(96, 72)
      ..lineTo(18, 72)
      ..close();
    c.drawPath(casco, _p(const Color(0xFF37474F)));
    c.drawRect(const Rect.fromLTWH(14, 66, 86, 2), _p(const Color(0xFFE53935)));
    c.drawRect(const Rect.fromLTWH(84, 42, 14, 18), _p(Colors.white));
    _ventanas(
      c,
      const Rect.fromLTWH(84, 42, 14, 8),
      1,
      3,
      const Color(0xFF0277BD),
    );
    const contenedores = [
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFFFA000),
      Color(0xFF8E24AA),
    ];
    for (var fila = 0; fila < 2; fila++) {
      for (var col = 0; col < 6; col++) {
        final r = Rect.fromLTWH(20 + col * 10.5, 52 - fila * 7, 10, 6.5);
        c.drawRect(r, _p(contenedores[(col + fila * 2) % 5]));
        c.drawRect(r, _trazo(const Color(0x55000000), 0.4));
      }
    }
  }

  void _aeropuerto(Canvas c) {
    _cielo(c, const Color(0xFF42A5F5), const Color(0xFFE1F5FE));
    _nube(c, const Offset(16, 30), 0.9);
    _nube(c, const Offset(118, 40), 0.7);
    // Avion despegando
    c.save();
    c.translate(84, 30);
    c.rotate(-0.22);
    const blanco = Color(0xFFFAFAFA);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-30, -4, 60, 8),
        const Radius.circular(4),
      ),
      _p(blanco),
    );
    final ala = Path()
      ..moveTo(-4, 0)
      ..lineTo(8, 0)
      ..lineTo(-8, 16)
      ..lineTo(-14, 16)
      ..close();
    c.drawPath(ala, _p(const Color(0xFFCFD8DC)));
    final cola = Path()
      ..moveTo(-30, -2)
      ..lineTo(-24, -2)
      ..lineTo(-32, -14)
      ..lineTo(-36, -14)
      ..close();
    c.drawPath(cola, _p(const Color(0xFF2E7D32)));
    c.drawRect(
      const Rect.fromLTWH(-22, -1.5, 44, 1.6),
      _p(const Color(0xFF2E7D32)),
    );
    for (var i = 0; i < 7; i++) {
      c.drawCircle(Offset(-16 + i * 5.0, -2), 0.9, _p(const Color(0xFF455A64)));
    }
    c.drawCircle(const Offset(27, -1), 2, _p(const Color(0xFF455A64)));
    c.restore();
    // Torre de control
    c.drawRect(
      const Rect.fromLTWH(130, 46, 8, 34),
      _p(const Color(0xFFB0BEC5)),
    );
    c.drawRect(
      const Rect.fromLTWH(125, 38, 18, 9),
      _p(const Color(0xFF546E7A)),
    );
    c.drawRect(
      const Rect.fromLTWH(127, 40, 14, 4),
      _p(const Color(0xFF80DEEA)),
    );
    // Terminal
    c.drawRect(const Rect.fromLTWH(0, 64, 70, 16), _p(const Color(0xFFCFD8DC)));
    _ventanas(
      c,
      const Rect.fromLTWH(0, 64, 70, 10),
      1,
      8,
      const Color(0xFF4FC3F7),
    );
    _suelo(c, 80, const Color(0xFF9CCC65));
    // Pista
    c.drawRect(const Rect.fromLTWH(0, 86, _w, 10), _p(const Color(0xFF424242)));
    for (var x = 4.0; x < _w; x += 16) {
      c.drawLine(
        Offset(x, 91),
        Offset(x + 8, 91),
        _trazo(Colors.white, 1.2)..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _universidad(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(140, 18), 7);
    _suelo(c, 82, const Color(0xFF7CB342));
    _arbol(c, 14, 86, 34);
    _arbol(c, 146, 86, 32, const Color(0xFF388E3C));
    // Escalinata
    for (var i = 0; i < 3; i++) {
      c.drawRect(
        Rect.fromLTWH(34 - i * 3.0, 76 + i * 3.0, 92 + i * 6.0, 3),
        _p(const Color(0xFFE0E0E0)),
      );
    }
    // Edificio con columnas
    c.drawRect(
      const Rect.fromLTWH(38, 42, 84, 34),
      _p(const Color(0xFFFFF8E1)),
    );
    for (var i = 0; i < 6; i++) {
      final x = 42.0 + i * 14.5;
      c.drawRect(Rect.fromLTWH(x, 46, 5, 30), _p(const Color(0xFFEEEEEE)));
      c.drawRect(Rect.fromLTWH(x - 1, 46, 7, 2), _p(const Color(0xFFBDBDBD)));
    }
    c.drawRect(const Rect.fromLTWH(34, 38, 92, 5), _p(const Color(0xFFD7CCC8)));
    final frontis = Path()
      ..moveTo(32, 38)
      ..lineTo(80, 22)
      ..lineTo(128, 38)
      ..close();
    c.drawPath(frontis, _p(const Color(0xFFBCAAA4)));
    c.drawCircle(const Offset(80, 32), 3.5, _p(const Color(0xFF2E7D32)));
    // Bandera
    c.drawLine(
      const Offset(80, 22),
      const Offset(80, 6),
      _trazo(const Color(0xFF757575), 0.8),
    );
    c.drawRect(const Rect.fromLTWH(80.5, 6, 4, 5), _p(const Color(0xFF2E7D32)));
    c.drawRect(const Rect.fromLTWH(84.5, 6, 4, 5), _p(Colors.white));
    c.drawRect(const Rect.fromLTWH(88.5, 6, 4, 5), _p(const Color(0xFFC62828)));
  }

  // ---------------------------------------------------------------------------
  // Escenas de categorias de reporte
  // ---------------------------------------------------------------------------
  void _bache(Canvas c) {
    _cieloDia(c);
    _nube(c, const Offset(20, 14));
    _suelo(c, 40, const Color(0xFF8BC34A));
    final via = Path()
      ..moveTo(64, 40)
      ..lineTo(96, 40)
      ..lineTo(172, 100)
      ..lineTo(-12, 100)
      ..close();
    c.drawPath(via, _p(const Color(0xFF546E7A)));
    c.drawLine(
      const Offset(80, 42),
      const Offset(80, 52),
      _trazo(Colors.white, 1)..strokeCap = StrokeCap.butt,
    );
    c.drawLine(
      const Offset(80, 58),
      const Offset(80, 70),
      _trazo(Colors.white, 1.6)..strokeCap = StrokeCap.butt,
    );
    // Bache
    c.drawOval(
      const Rect.fromLTWH(84, 74, 40, 14),
      _p(const Color(0xFF263238)),
    );
    c.drawOval(const Rect.fromLTWH(88, 77, 32, 8), _p(const Color(0xFF37474F)));
    for (final d in [
      const Offset(-6, -2),
      const Offset(6, 4),
      const Offset(-4, 6),
    ]) {
      c.drawLine(
        const Offset(104, 81) + d * 3,
        const Offset(104, 81) + d * 4.5,
        _trazo(const Color(0xFF263238), 0.8),
      );
    }
    // Cono
    final cono = Path()
      ..moveTo(52, 90)
      ..lineTo(58, 70)
      ..lineTo(64, 90)
      ..close();
    c.drawPath(cono, _p(const Color(0xFFFF6D00)));
    c.drawRect(const Rect.fromLTWH(55, 78, 6, 3), _p(Colors.white));
    c.drawRect(const Rect.fromLTWH(48, 90, 20, 3), _p(const Color(0xFFE65100)));
  }

  void _carga(Canvas c) {
    _cielo(c, const Color(0xFFB0BEC5), const Color(0xFFECEFF1));
    // Bodega
    c.drawRect(const Rect.fromLTWH(0, 20, 70, 62), _p(const Color(0xFF90A4AE)));
    c.drawRect(
      const Rect.fromLTWH(10, 40, 50, 42),
      _p(const Color(0xFF546E7A)),
    );
    for (var y = 44.0; y < 82; y += 4) {
      c.drawLine(
        Offset(10, y),
        Offset(60, y),
        _trazo(const Color(0xFF455A64), 0.6),
      );
    }
    _suelo(c, 82, const Color(0xFF757575));
    _camion(c, const Offset(108, 92), abierto: true);
    // Cajas en el camion y caidas
    _caja(c, const Rect.fromLTWH(110, 63, 9, 7));
    _caja(c, const Rect.fromLTWH(121, 63, 9, 7));
    _caja(c, const Rect.fromLTWH(115, 56, 9, 7));
    _caja(c, const Rect.fromLTWH(140, 86, 10, 8), 0.5);
    _caja(c, const Rect.fromLTWH(78, 86, 11, 8), -0.3);
    _caja(c, const Rect.fromLTWH(90, 88, 9, 7), 0.9);
    // Senal de golpe
    c.drawLine(
      const Offset(145, 78),
      const Offset(150, 74),
      _trazo(const Color(0xFFE53935), 1),
    );
    c.drawLine(
      const Offset(147, 81),
      const Offset(154, 80),
      _trazo(const Color(0xFFE53935), 1),
    );
  }

  void _callesNoche(Canvas c) {
    _cielo(c, const Color(0xFF0D1B3E), const Color(0xFF283593));
    c.drawCircle(const Offset(130, 18), 8, _p(const Color(0xFFFFF9C4)));
    c.drawCircle(const Offset(134, 15), 7, _p(const Color(0xFF13214A)));
    for (final e in const [
      Offset(20, 10),
      Offset(46, 22),
      Offset(70, 8),
      Offset(100, 26),
      Offset(150, 34),
      Offset(88, 16),
    ]) {
      c.drawCircle(e, 0.9, _p(Colors.white70));
    }
    for (var i = 0; i < 6; i++) {
      final alto = 30.0 + (i * 11 % 17);
      final r = Rect.fromLTWH(i * 28.0, 80 - alto, 24, alto);
      c.drawRect(r, _p(const Color(0xFF1A237E)));
      _ventanas(
        c,
        r,
        3,
        2,
        i == 2 ? const Color(0xFFFFE082) : const Color(0xFF283593),
      );
    }
    _suelo(c, 80, const Color(0xFF263238));
    c.drawRect(const Rect.fromLTWH(0, 78, _w, 2), _p(const Color(0xFF455A64)));
    // Farola encendida
    c.drawPath(
      Path()
        ..moveTo(30, 44)
        ..lineTo(14, 80)
        ..lineTo(46, 80)
        ..close(),
      _p(const Color(0x33FFF59D)),
    );
    c.drawLine(
      const Offset(30, 80),
      const Offset(30, 40),
      _trazo(const Color(0xFF90A4AE), 1.6),
    );
    c.drawCircle(const Offset(30, 41), 3, _p(const Color(0xFFFFF59D)));
    // Farola apagada (el problema reportado)
    c.drawLine(
      const Offset(110, 80),
      const Offset(110, 40),
      _trazo(const Color(0xFF546E7A), 1.6),
    );
    c.drawCircle(const Offset(110, 41), 3, _p(const Color(0xFF37474F)));
    c.drawCircle(
      const Offset(110, 41),
      3,
      _trazo(const Color(0xFFE53935), 0.7),
    );
    // Senal de alerta
    final alerta = Path()
      ..moveTo(128, 60)
      ..lineTo(138, 76)
      ..lineTo(118, 76)
      ..close();
    c.drawPath(alerta, _p(const Color(0xFFFFC107)));
    c.drawLine(
      const Offset(128, 65),
      const Offset(128, 71),
      _trazo(const Color(0xFF212121), 1.3),
    );
    c.drawCircle(const Offset(128, 73.5), 0.8, _p(const Color(0xFF212121)));
  }

  void _reciclaje(Canvas c) {
    _cieloDia(c);
    _sol(c, const Offset(24, 18), 7);
    _suelo(c, 74, const Color(0xFF9CCC65));
    _arbol(c, 136, 80, 50, const Color(0xFF2E7D32));
    const colores = [Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFDD835)];
    for (var i = 0; i < 3; i++) {
      final x = 18.0 + i * 34;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 52, 26, 34),
          const Radius.circular(2),
        ),
        _p(colores[i]),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, 48, 30, 5),
          const Radius.circular(2),
        ),
        _p(Color.lerp(colores[i], Colors.black, 0.25)!),
      );
      // Simbolo de reciclaje (tres flechas en triangulo)
      final centro = Offset(x + 13, 70);
      for (var k = 0; k < 3; k++) {
        final a1 = -math.pi / 2 + k * 2 * math.pi / 3;
        final a2 = a1 + 2 * math.pi / 3 * 0.7;
        final p1 = centro + Offset(math.cos(a1), math.sin(a1)) * 7;
        final p2 = centro + Offset(math.cos(a2), math.sin(a2)) * 7;
        c.drawLine(p1, p2, _trazo(Colors.white, 1.6));
        final dir = (p2 - p1) / (p2 - p1).distance;
        final normal = Offset(-dir.dy, dir.dx);
        c.drawPath(
          Path()
            ..moveTo(p2.dx + dir.dx * 2, p2.dy + dir.dy * 2)
            ..lineTo(p2.dx + normal.dx * 2, p2.dy + normal.dy * 2)
            ..lineTo(p2.dx - normal.dx * 2, p2.dy - normal.dy * 2)
            ..close(),
          _p(Colors.white),
        );
      }
    }
    // Botella y hojas en el suelo
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 86, 10, 4),
        const Radius.circular(2),
      ),
      _p(const Color(0xFF80DEEA)),
    );
    for (final h in const [Offset(100, 92), Offset(150, 90), Offset(8, 94)]) {
      c.drawOval(
        Rect.fromCenter(center: h, width: 5, height: 2.5),
        _p(const Color(0xFF558B2F)),
      );
    }
  }
}
