import 'package:flutter/material.dart';

import '../../domain/entities/zona.dart';
import '../controllers/catalogo_controller.dart';

/// Modulo 2.1 - Catalogo bidimensional.
///
/// `GridView.builder` con `SliverGridDelegateWithMaxCrossAxisExtent` y
/// `childAspectRatio` para que la grilla se adapte a cualquier ancho de
/// pantalla (telapeta, tableta o zona ancha).
class CatalogoView extends StatelessWidget {
  const CatalogoView({super.key, required this.catalogo});

  final CatalogoController catalogo;

  static const List<IconData> _iconos = [
    Icons.route_rounded,
    Icons.local_shipping_rounded,
    Icons.inventory_2_rounded,
    Icons.warning_amber_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: catalogo,
      builder: (context, _) {
        if (catalogo.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        final zonas = catalogo.zonasFiltradas;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todo'),
                    selected: catalogo.riesgoActivo == null,
                    onSelected: (_) => catalogo.aplicarFiltroDeRiesgo(null),
                  ),
                  for (var riesgo = 1; riesgo <= 4; riesgo++)
                    FilterChip(
                      label: Text(Zona.nivelesRiesgo[riesgo - 1]),
                      selected: catalogo.riesgoActivo == riesgo,
                      onSelected: (_) =>
                          catalogo.aplicarFiltroDeRiesgo(riesgo),
                    ),
                ],
              ),
            ),
            Expanded(
              child: zonas.isEmpty
                  ? const Center(
                      child: Text('No hay zonas para este nivel de riesgo'),
                    )
                  : GridView.builder(
                      key: const Key('grilla_zonas'),
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: zonas.length,
                      itemBuilder: (context, indice) {
                        final zona = zonas[indice];
                        final esquema = Theme.of(context).colorScheme;
                        final colorRiesgo = switch (zona.riesgo) {
                          1 => const Color(0xFF16A34A),
                          2 => const Color(0xFFF59E0B),
                          3 => const Color(0xFFEA580C),
                          _ => const Color(0xFFDC2626),
                        };

                        return Card(
                          key: Key('zona_${zona.id}'),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _mostrarDetalle(context, zona),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _iconos[zona.tipoIcono],
                                    size: 34,
                                    color: esquema.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    zona.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    zona.ruta,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const Spacer(),
                                  // Wrap evita el RenderFlex Overflow en
                                  // celdas angostas (celular en vertical).
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorRiesgo
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          zona.etiquetaRiesgo,
                                          style: TextStyle(
                                            color: colorRiesgo,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${zona.entregasPendientes} pedidos',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetalle(BuildContext context, Zona zona) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zona.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Ruta: ${zona.ruta}'),
            Text('Riesgo: ${zona.etiquetaRiesgo}'),
            Text('Entregas pendientes: ${zona.entregasPendientes}'),
            Text(
              'Requiere atencion: ${zona.requiereAtencion ? "Si" : "No"}',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
