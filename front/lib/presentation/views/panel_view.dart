import 'package:flutter/material.dart';

import '../../domain/entities/reporte.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/reporte_controller.dart';
import 'estilos.dart';
import 'ilustraciones.dart';

/// Pestana 1 - Panel: `CustomScrollView` + `SliverAppBar` colapsable,
/// filtros en `Wrap` y listado observable de reportes.
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([reportes, catalogo]),
      builder: (context, _) {
        final lista = reportes.reportesFiltrados;
        return CustomScrollView(
          slivers: [
            _Cabecera(reportes: reportes, catalogo: catalogo),
            SliverToBoxAdapter(child: _Filtros(reportes: reportes)),
            if (reportes.cargando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (lista.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Vacio(onNuevoReporte: onNuevoReporte),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: TarjetaReporte(
                        reporte: lista[i],
                        onEliminar: () => reportes.eliminar(lista[i].id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.reportes, required this.catalogo});

  final ReporteController reportes;
  final CatalogoController catalogo;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: Estilos.verde,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
        title: const Text(
          'EcoTrack & RutaSegura',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Estilos.verde, Estilos.verdeAzulado],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Indicador(
                      icono: Icons.description_rounded,
                      valor: reportes.total,
                      texto: 'Reportes',
                    ),
                    _Indicador(
                      icono: Icons.priority_high_rounded,
                      valor: reportes.totalCriticos,
                      texto: 'Criticos',
                    ),
                    _Indicador(
                      icono: Icons.cloud_upload_rounded,
                      valor: reportes.totalPendientes,
                      texto: 'Pendientes',
                    ),
                    _Indicador(
                      icono: Icons.place_rounded,
                      valor: catalogo.totalAtencion,
                      texto: 'Zonas en alerta',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icono,
    required this.valor,
    required this.texto,
  });

  final IconData icono;
  final int valor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$valor $texto',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.reportes});

  final ReporteController reportes;

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: reportes.categoriaActiva == null,
                    onSelected: (_) => reportes.filtrarPorCategoria(null),
                  ),
                  for (final categoria in Reporte.categorias)
                    FilterChip(
                      avatar: Icon(Estilos.iconoCategoria(categoria), size: 18),
                      label: Text(categoria),
                      selected: reportes.categoriaActiva == categoria,
                      onSelected: (_) =>
                          reportes.filtrarPorCategoria(categoria),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: reportes.sincronizando
                        ? null
                        : reportes.sincronizar,
                    icon: reportes.sincronizando
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(esAncho ? 'Sincronizar ahora' : 'Sincronizar'),
                  ),
                ],
              ),
              if (reportes.mensaje != null) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: Text(reportes.mensaje!),
                  leading: const Icon(Icons.info_outline_rounded),
                  actions: [
                    TextButton(
                      onPressed: reportes.limpiarMensaje,
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de un reporte con su prioridad y su estado de sincronizacion.
class TarjetaReporte extends StatelessWidget {
  const TarjetaReporte({
    super.key,
    required this.reporte,
    required this.onEliminar,
  });

  final Reporte reporte;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = Estilos.colorPrioridad(reporte.prioridad);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 480 ? 84 : 120,
              height: MediaQuery.sizeOf(context).width < 480 ? 84 : 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Ilustracion(
                    escena: Escena.deCategoria(reporte.categoria),
                    radio: 10,
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: tema.colorScheme.surface.withValues(
                        alpha: 0.9,
                      ),
                      foregroundColor: color,
                      child: Icon(
                        Estilos.iconoCategoria(reporte.categoria),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reporte.titulo, style: tema.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${reporte.resumen}  ·  ${reporte.fechaCorta}',
                    style: tema.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reporte.detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Etiqueta(
                        icono: reporte.sincronizado
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        texto: reporte.estadoSincronizacion,
                        color: reporte.sincronizado
                            ? Estilos.verde
                            : tema.colorScheme.outline,
                      ),
                      if (reporte.esCritico)
                        _Etiqueta(
                          icono: Icons.bolt_rounded,
                          texto: 'Critico',
                          color: color,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar reporte',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.onNuevoReporte});

  final VoidCallback onNuevoReporte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          const Text('No hay reportes en esta categoria'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onNuevoReporte,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar reporte'),
          ),
        ],
      ),
    );
  }
}
