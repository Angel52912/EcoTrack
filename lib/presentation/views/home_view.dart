import 'package:flutter/material.dart';

import '../controllers/catalogo_controller.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'catalogo_view.dart';
import 'nuevo_reporte_view.dart';
import 'panel_view.dart';

/// Modulo 1 - Capa `presentation/views`.
///
/// Contenedor pasivo con `NavigationBar` (Material 3). Las tres secciones se
/// mantienen vivas con `IndexedStack` para no perder estado al cambiar de
/// pestana.
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.reportes,
    required this.catalogo,
    required this.formulario,
  });

  final ReporteController reportes;
  final CatalogoController catalogo;
  final FormularioController formulario;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _indice = 0;

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          // Pestana 1: panel con SliverAppBar + Wrap + lista observable.
          PanelView(
            reportes: widget.reportes,
            catalogo: widget.catalogo,
            onNuevoReporte: () => _irA(2),
          ),
          // Pestana 2: catalogo en GridView.
          CatalogoView(catalogo: widget.catalogo),
          // Pestana 3: formulario validado.
          NuevoReporteView(
            formulario: widget.formulario,
            reportes: widget.reportes,
            onGuardado: () => _irA(0),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Catalogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Nuevo',
          ),
        ],
      ),
    );
  }
}
