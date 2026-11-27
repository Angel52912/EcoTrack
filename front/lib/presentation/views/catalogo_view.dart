import 'package:flutter/material.dart';

import '../../domain/entities/zona.dart';
import '../controllers/catalogo_controller.dart';
import 'estilos.dart';
import 'ilustraciones.dart';

/// Pestana 2 - Catalogo bidimensional: `GridView.builder` con
/// `SliverGridDelegateWithMaxCrossAxisExtent` (se adapta al ancho).
class CatalogoView extends StatelessWidget {
  const CatalogoView({super.key, required this.catalogo});

  final CatalogoController catalogo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo de zonas')),
      body: ListenableBuilder(
        listenable: catalogo,
        builder: (context, _) {
          final zonas = catalogo.zonasFiltradas;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todo'),
                      selected: catalogo.riesgoActivo == null,
                      onSelected: (_) => catalogo.filtrarPorRiesgo(null),
                    ),
                    for (var riesgo = 1; riesgo <= 4; riesgo++)
                      ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: Estilos.colorRiesgo(riesgo),
                          radius: 6,
                        ),
                        label: Text(Zona.nivelesRiesgo[riesgo - 1]),
                        selected: catalogo.riesgoActivo == riesgo,
                        onSelected: (_) => catalogo.filtrarPorRiesgo(riesgo),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  '${zonas.length} zonas · ${catalogo.totalEntregas} entregas pendientes en total',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: catalogo.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : zonas.isEmpty
                    ? const Center(
                        child: Text('No hay zonas para este nivel de riesgo'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: zonas.length,
                        itemBuilder: (context, i) => TarjetaZona(
                          zona: zonas[i],
                          onTap: () => _mostrarDetalle(context, zonas[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, Zona zona) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Ilustracion(escena: Escena.deLugar(zona.lugar)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Estilos.iconoZona(zona.tipoIcono),
                  color: Estilos.colorRiesgo(zona.riesgo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zona.nombre,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Ruta: ${zona.ruta}'),
            Text('Riesgo: ${zona.etiquetaRiesgo}'),
            Text('Entregas pendientes: ${zona.entregasPendientes}'),
            const SizedBox(height: 8),
            Text(
              zona.requiereAtencion
                  ? 'Esta zona requiere atencion del supervisor.'
                  : 'Zona operando con normalidad.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: zona.requiereAtencion
                    ? Estilos.colorRiesgo(4)
                    : Estilos.verde,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TarjetaZona extends StatelessWidget {
  const TarjetaZona({super.key, required this.zona, required this.onTap});

  final Zona zona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = Estilos.colorRiesgo(zona.riesgo);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Ilustracion(escena: Escena.deLugar(zona.lugar), radio: 0),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: tema.colorScheme.surface.withValues(
                        alpha: 0.9,
                      ),
                      foregroundColor: color,
                      child: Icon(Estilos.iconoZona(zona.tipoIcono), size: 18),
                    ),
                  ),
                  if (zona.requiereAtencion)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Tooltip(
                        message: 'Requiere atencion',
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: tema.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          child: Icon(
                            Icons.error_rounded,
                            size: 20,
                            color: Estilos.colorRiesgo(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zona.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(zona.ruta, style: tema.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          zona.etiquetaRiesgo,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${zona.entregasPendientes} entregas',
                        style: tema.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
