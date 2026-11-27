import 'package:flutter/material.dart';

import '../controllers/catalogo_controller.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'catalogo_view.dart';
import 'nuevo_reporte_view.dart';
import 'panel_view.dart';

/// Contenedor con navegacion responsiva: `NavigationBar` en telefono y
/// `NavigationRail` en pantallas anchas. `IndexedStack` conserva el estado
/// de cada pestana.
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

  static const _destinos = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Panel'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Catalogo'),
    (Icons.add_circle_outline, Icons.add_circle, 'Nuevo'),
  ];

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    final contenido = IndexedStack(
      index: _indice,
      children: [
        PanelView(
          reportes: widget.reportes,
          catalogo: widget.catalogo,
          onNuevoReporte: () => _irA(2),
        ),
        CatalogoView(catalogo: widget.catalogo),
        NuevoReporteView(
          formulario: widget.formulario,
          reportes: widget.reportes,
          onGuardado: () => _irA(0),
        ),
      ],
    );

    final esAncho = MediaQuery.sizeOf(context).width >= 840;
    if (esAncho) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _indice,
              onDestinationSelected: _irA,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Icon(
                  Icons.eco_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                for (final (icono, seleccionado, texto) in _destinos)
                  NavigationRailDestination(
                    icon: Icon(icono),
                    selectedIcon: Icon(seleccionado),
                    label: Text(texto),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: contenido),
          ],
        ),
      );
    }

    return Scaffold(
      body: contenido,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: [
          for (final (icono, seleccionado, texto) in _destinos)
            NavigationDestination(
              icon: Icon(icono),
              selectedIcon: Icon(seleccionado),
              label: texto,
            ),
        ],
      ),
    );
  }
}
