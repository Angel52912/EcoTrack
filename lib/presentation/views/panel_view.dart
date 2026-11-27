import 'package:flutter/material.dart';

import '../../domain/entities/reporte.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/reporte_controller.dart';
import 'estilos.dart';
import 'ilustraciones.dart';

/// Modulo 2.1 y 2.3 - Vista pasiva del panel principal.
///
/// `CustomScrollView` con `SliverAppBar` colapsable, barra de filtros `Wrap`
/// (sin RenderFlex Overflow) y lista observable. **No contiene logica de
/// negocio, SQL ni HTTP**: todo llega ya calculado desde los controladores.
class PanelView extends StatelessWidget {
  const PanelView({
    super.key,
    required this.reportes,
    required this.catalogo,
    required this.onNuevoReporte,
  });

  final ReporteController reportes;
  final CatalogoController catalogo;
  final VoidCallback onNuevoReporte;

  /// Accion del boton "Sincronizar ahora".
  ///
  /// Orquesta los dos controladores: primero sube la cola de reportes y
  /// descarga el catalogo, luego refresca el resumen para que el contador
  /// "Pendientes de sincronizar" baje a 0. No hay SQL ni HTTP aqui.
  Future<void> _sincronizar() async {
    await catalogo.sincronizar();
    await reportes.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 720;

    return ListenableBuilder(
      listenable: reportes,
      builder: (context, _) {
        return CustomScrollView(
          key: const Key('panel_scroll'),
          slivers: [
            // ------------------------------------------------------------------
            // 2.1 SliverAppBar colapsable
            // ------------------------------------------------------------------
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 190,
              title: const Text('EcoTrack & RutaSegura'),
              actions: [
                IconButton(
                  tooltip: 'Sincronizar con la nube',
                  onPressed: catalogo.sincronizando ? null : _sincronizar,
                  icon: const Icon(Icons.cloud_sync_outlined),
                ),
                IconButton(
                  tooltip: 'Nuevo reporte',
                  onPressed: onNuevoReporte,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                title: const Text('EcoTrack & RutaSegura'),
                background: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF14532D), Color(0xFF16A34A)],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: Icon(
                        Icons.route_rounded,
                        size: 110,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ------------------------------------------------------------------
            // 2.1 Barra de filtros adaptativa con Wrap
            // ------------------------------------------------------------------
            SliverToBoxAdapter(
              child: _BarraDeFiltros(
                reportes: reportes,
                catalogo: catalogo,
                esAncho: esAncho,
              ),
            ),

            // Resumen observable del listado.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Reportes en campo: ${reportes.total}  |  '
                  'Criticos: ${reportes.totalCriticos}  |  '
                  'Pendientes de sincronizar: ${reportes.pendientesDeSincronizar}',
                  key: const Key('resumen_panel'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),

            if (reportes.cargando)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 3),
              ),

            if (reportes.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    reportes.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),

            // ------------------------------------------------------------------
            // 2.3 ListenableBuilder acotado: solo repinta la lista modificada
            // ------------------------------------------------------------------
            ListenableBuilder(
              listenable: reportes,
              builder: (context, _) {
                if (reportes.reportes.isEmpty && !reportes.cargando) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Sin reportes para este filtro.\nRegistra la primera novedad de campo.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, indice) => _TarjetaReporte(
                      reporte: reportes.reportes[indice],
                      onEliminar: () =>
                          reportes.eliminar(reportes.reportes[indice].id),
                    ),
                    childCount: reportes.reportes.length,
                  ),
                );
              },
            ),

            // Espacio para la NavigationBar inferior.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }
}

/// Barra de filtros construida con `Wrap`: nunca desborda (RenderFlex
/// Overflow) porque las fichas pasan de fila automaticamente.
class _BarraDeFiltros extends StatelessWidget {
  const _BarraDeFiltros({
    required this.reportes,
    required this.catalogo,
    required this.esAncho,
  });

  final ReporteController reportes;
  final CatalogoController catalogo;
  final bool esAncho;

  /// Mismo flujo que el icono del `SliverAppBar`: sube la cola de reportes,
  /// descarga el catalogo y refresca el resumen observable del panel.
  Future<void> _sincronizar() async {
    await catalogo.sincronizar();
    await reportes.cargar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: catalogo,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: reportes.categoriaActiva == null,
                    onSelected: (_) => reportes.aplicarFiltro(null),
                  ),
                  for (final categoria in reportes.categoriasDisponibles)
                    FilterChip(
                      label: Text(categoria),
                      selected: reportes.categoriaActiva == categoria,
                      onSelected: (_) => reportes.aplicarFiltro(categoria),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: catalogo.sincronizando ? null : _sincronizar,
                    icon: catalogo.sincronizando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(esAncho ? 'Sincronizar ahora' : 'Sincronizar'),
                  ),
                ],
              ),
              if (catalogo.estadoRed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MaterialBanner(
                    content: Text(catalogo.estadoRed!),
                    leading: Icon(
                      catalogo.sincronizando
                          ? Icons.cloud_sync_outlined
                          : Icons.wifi_off_rounded,
                    ),
                    actions: [
                      TextButton(
                        onPressed: catalogo.limpiarEstadoRed,
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tarjeta individual de reporte (solo lectura de la entidad).
class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({required this.reporte, required this.onEliminar});

  final Reporte reporte;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        key: Key('tarjeta_${reporte.id}'),
        // Miniatura ilustrada de la categoria + badge de prioridad
        // (los colores salen de `Estilos`, no del build).
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Ilustracion(
                escena: Escena.deCategoria(reporte.categoria),
                radio: 24,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Estilos.colorPrioridad(reporte.prioridad),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '${reporte.prioridad}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(reporte.titulo),
        subtitle: Text(
          '${reporte.resumen}\n'
          '${reporte.sincronizado ? "Sincronizado" : "Pendiente de sincronizar"}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Eliminar reporte',
          onPressed: onEliminar,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
