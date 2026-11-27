import 'package:flutter/material.dart';

import 'data/repositorio_memoria.dart';
import 'presentation/controllers/catalogo_controller.dart';
import 'presentation/controllers/formulario_controller.dart';
import 'presentation/controllers/reporte_controller.dart';
import 'presentation/views/ecotrack_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inyeccion de dependencias: data -> dominio -> presentation.
  // Para conectar el backend real basta con reemplazar RepositorioMemoria.
  final repositorio = RepositorioMemoria();

  final reportes = ReporteController(repositorio: repositorio);
  final catalogo = CatalogoController(repositorio: repositorio);
  final formulario = FormularioController();

  runApp(
    EcoTrackApp(reportes: reportes, catalogo: catalogo, formulario: formulario),
  );

  reportes.cargar();
  catalogo.cargar();
}
