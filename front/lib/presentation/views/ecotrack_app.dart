import 'package:flutter/material.dart';

import '../controllers/catalogo_controller.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'estilos.dart';
import 'home_view.dart';

class EcoTrackApp extends StatelessWidget {
  const EcoTrackApp({
    super.key,
    required this.reportes,
    required this.catalogo,
    required this.formulario,
  });

  final ReporteController reportes;
  final CatalogoController catalogo;
  final FormularioController formulario;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack & RutaSegura',
      debugShowCheckedModeBanner: false,
      theme: Estilos.tema(Brightness.light),
      darkTheme: Estilos.tema(Brightness.dark),
      home: HomeView(
        reportes: reportes,
        catalogo: catalogo,
        formulario: formulario,
      ),
    );
  }
}
