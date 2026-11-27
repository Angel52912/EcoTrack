import 'package:flutter/material.dart';

import '../../domain/entities/zona.dart';

/// Traducciones de datos del dominio a elementos visuales. Es el unico lugar
/// donde un indice o una prioridad se convierten en color o icono.
class Estilos {
  Estilos._();

  static const Color verde = Color(0xFF2E7D32);
  static const Color verdeAzulado = Color(0xFF00695C);

  static ThemeData tema(Brightness brillo) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: verde, brightness: brillo),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
  );

  static IconData iconoZona(int tipo) => switch (tipo) {
    Zona.tipoCamion => Icons.local_shipping_rounded,
    Zona.tipoPaquete => Icons.inventory_2_rounded,
    Zona.tipoAlerta => Icons.warning_amber_rounded,
    _ => Icons.alt_route_rounded,
  };

  static IconData iconoCategoria(String categoria) => switch (categoria) {
    'Carga' => Icons.inventory_rounded,
    'Seguridad' => Icons.shield_rounded,
    'Ambiental' => Icons.eco_rounded,
    _ => Icons.route_rounded,
  };

  /// Color del nivel de riesgo (1..4).
  static Color colorRiesgo(int riesgo) => switch (riesgo) {
    4 => const Color(0xFFC62828),
    3 => const Color(0xFFEF6C00),
    2 => const Color(0xFFF9A825),
    _ => const Color(0xFF2E7D32),
  };

  /// Color de la prioridad (1..5).
  static Color colorPrioridad(int prioridad) => switch (prioridad) {
    5 => const Color(0xFFC62828),
    4 => const Color(0xFFEF6C00),
    3 => const Color(0xFFF9A825),
    2 => const Color(0xFF1565C0),
    _ => const Color(0xFF607D8B),
  };
}
