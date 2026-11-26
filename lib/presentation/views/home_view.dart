import 'package:flutter/material.dart';

import '../controllers/alerta_controller.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'alerta_view.dart';
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
    required this.alertas,
  });

  final ReporteController reportes;
  final CatalogoController catalogo;
  final FormularioController formulario;
  final AlertaController alertas;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _indice = 0;

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  void initState() {
    super.initState();
    // Modulo 4.1: aqui (y no en build) se empieza a escuchar el Stream
    // continuo del acelerometro a traves del controlador.
    widget.alertas.iniciarMonitoreo();
  }

  @override
  void dispose() {
    // Modulo 4.4: cancela la suscripcion del sensor, el temporizador y
    // libera el reproductor de audio.
    widget.alertas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
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
                alertas: widget.alertas,
                onGuardado: () => _irA(0),
              ),
              // Pestana 4: sensores, audio y simulacion manual (Modulo 4).
              AlertaView(alertas: widget.alertas),
            ],
          ),
          // Alerta visual flotante: se ve en cualquier pestana.
          AlertaFlotante(alertas: widget.alertas),
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
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Alerta',
          ),
        ],
      ),
    );
  }
}
