import 'package:flutter/material.dart';

import '../../domain/entities/alerta_impacto.dart';
import '../controllers/alerta_controller.dart';

/// Modulo 4 - Vista pasiva del modo "Alerta de Impacto o Emergencia en Ruta".
///
/// No mide el sensor ni decide umbrales: solo observa [AlertaController] y
/// ofrece el boton de simulacion manual.
class AlertaView extends StatelessWidget {
  const AlertaView({super.key, required this.alertas});

  final AlertaController alertas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: alertas,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            key: const Key('vista_alerta_scroll'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Sensores y emergencia en ruta',
                style: tema.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Monitoreo del acelerometro en segundo termino: '
                'cualquier eje que supere ${alertas.umbral} m/s2 dispara '
                'la alerta visual, el audio y la notificacion.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  key: const Key('estado_acelerometro'),
                  leading: Icon(
                    alertas.monitoreando
                        ? Icons.sensors_rounded
                        : Icons.sensors_off_outlined,
                    color: alertas.monitoreando
                        ? tema.colorScheme.primary
                        : tema.colorScheme.outline,
                  ),
                  title: Text(
                    alertas.monitoreando
                        ? 'Acelerometro en escucha'
                        : 'Acelerometro detenido',
                  ),
                  subtitle: Text(
                    'Umbral: ${alertas.umbral} m/s2  |  '
                    'Eventos: ${alertas.totalAlertas}',
                  ),
                  trailing: alertas.enEnfriamiento
                      ? const Icon(Icons.hourglass_top)
                      : const Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 12),

              if (alertas.alertaActiva)
                _TarjetaAlerta(alerta: alertas.alerta!, alertas: alertas)
              else
                Card(
                  key: const Key('sin_alertas'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sin impactos registrados. El sensor esta activo '
                      'mientras la aplicacion permanece abierta.',
                      style: tema.textTheme.bodyMedium,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('boton_simular_alerta'),
                onPressed: alertas.enEnfriamiento
                    ? null
                    : () => alertas.simularAlerta(),
                icon: const Icon(Icons.sos_outlined),
                label: Text(
                  alertas.enEnfriamiento
                      ? 'Cooldown activo'
                      : 'Simular impacto manual',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El boton usa el mismo flujo que una lectura real '
                '(${alertas.cooldown.inSeconds}s de enfriamiento).',
                style: tema.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Banner flotante: hace visible la emergencia aunque el operador este en
/// otra pestana (se apila sobre el `IndexedStack` de [HomeView]).
class AlertaFlotante extends StatelessWidget {
  const AlertaFlotante({super.key, required this.alertas});

  final AlertaController alertas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: alertas,
      builder: (context, _) {
        final alerta = alertas.alerta;
        if (alerta == null) return const SizedBox.shrink();

        final tema = Theme.of(context);
        return Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: SafeArea(
            child: Card(
              key: const Key('banner_alerta_impacto'),
              color: tema.colorScheme.errorContainer,
              elevation: 8,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: tema.colorScheme.error,
                ),
                title: Text(
                  'Alerta de impacto en ruta',
                  style: TextStyle(
                    color: tema.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Eje ${alerta.eje}: ${alerta.magnitudFormateada} m/s2 '
                  '(${alerta.origen})',
                  style: TextStyle(color: tema.colorScheme.onErrorContainer),
                ),
                trailing: IconButton(
                  tooltip: 'Cerrar alerta',
                  onPressed: alertas.limpiarAlerta,
                  icon: Icon(
                    Icons.close,
                    color: tema.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta, required this.alertas});

  final AlertaImpacto alerta;
  final AlertaController alertas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      key: const Key('tarjeta_alerta_impacto'),
      color: tema.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: tema.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergencia detectada',
                    style: tema.textTheme.titleMedium?.copyWith(
                      color: tema.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Eje ${alerta.eje} - ${alerta.magnitudFormateada} m/s2',
              style: TextStyle(color: tema.colorScheme.onErrorContainer),
            ),
            Text(
              'Origen: ${alerta.origen}',
              style: TextStyle(color: tema.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: alertas.limpiarAlerta,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar recepcion'),
            ),
          ],
        ),
      ),
    );
  }
}
