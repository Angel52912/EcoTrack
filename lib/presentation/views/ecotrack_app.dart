import 'package:flutter/material.dart';

import '../../configuracion.dart';
import '../controllers/alerta_controller.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'estilos.dart';
import 'home_view.dart';

/// Raiz de la interfaz (Material 3). Recibe los controladores ya inyectados
/// desde `main.dart`: la vista no crea fuentes de datos ni hace HTTP.
class EcoTrackApp extends StatelessWidget {
  EcoTrackApp({
    super.key,
    required this.reportes,
    required this.catalogo,
    required this.formulario,
    AlertaController? alertas,
  }) : alertas = alertas ?? AlertaController.sinServicio();

  final ReporteController reportes;
  final CatalogoController catalogo;
  final FormularioController formulario;
  final AlertaController alertas;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.nombreApp,
      debugShowCheckedModeBanner: false,
      // Tema unico en `Estilos` (traduccion de datos a elementos visuales).
      theme: Estilos.tema(Brightness.light),
      darkTheme: Estilos.tema(Brightness.dark),
      themeMode: ThemeMode.system,
      home: HomeView(
        reportes: reportes,
        catalogo: catalogo,
        formulario: formulario,
        alertas: alertas,
      ),
    );
  }
}
