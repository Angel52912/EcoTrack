import 'package:flutter/material.dart';

import '../../domain/entities/reporte.dart';
import '../../domain/validadores/reglas_reporte.dart';
import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';
import 'estilos.dart';

/// Pestana 3 - Formulario: `Form` + `GlobalKey<FormState>`, validaciones con
/// RegExp y boton bloqueado (`onPressed: null`) hasta aceptar los terminos.
class NuevoReporteView extends StatefulWidget {
  const NuevoReporteView({
    super.key,
    required this.formulario,
    required this.reportes,
    required this.onGuardado,
  });

  final FormularioController formulario;
  final ReporteController reportes;
  final VoidCallback onGuardado;

  @override
  State<NuevoReporteView> createState() => _NuevoReporteViewState();
}

class _NuevoReporteViewState extends State<NuevoReporteView> {
  final _claveFormulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _titulo = TextEditingController();
  final _detalle = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    _titulo.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_claveFormulario.currentState?.validate() ?? false)) return;

    final formulario = widget.formulario;
    final reporte = formulario.construir(
      codigo: _codigo.text,
      titulo: _titulo.text,
      detalle: _detalle.text,
    );

    formulario.marcarGuardando(true);
    await widget.reportes.agregar(reporte);
    if (!mounted) return;

    _claveFormulario.currentState?.reset();
    _codigo.clear();
    _titulo.clear();
    _detalle.clear();
    formulario.reiniciar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reporte ${reporte.codigo} guardado (pendiente de sincronizar)',
        ),
      ),
    );
    widget.onGuardado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte de campo')),
      body: ListenableBuilder(
        listenable: widget.formulario,
        builder: (context, _) {
          final formulario = widget.formulario;
          final tema = Theme.of(context);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _claveFormulario,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Registra la novedad. Se guarda en el dispositivo y se '
                        'sincroniza cuando haya conexion.',
                        style: tema.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('campo_codigo'),
                        controller: _codigo,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Codigo *',
                          hintText: 'EC-2026-AL',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                        validator: ReglasReporte.validarCodigo,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('campo_titulo'),
                        controller: _titulo,
                        decoration: const InputDecoration(
                          labelText: 'Titulo *',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: ReglasReporte.validarTitulo,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('campo_detalle'),
                        controller: _detalle,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 400,
                        decoration: const InputDecoration(
                          labelText: 'Detalle de campo *',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        validator: ReglasReporte.validarDetalle,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: formulario.categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: [
                          for (final categoria in Reporte.categorias)
                            DropdownMenuItem(
                              value: categoria,
                              child: Row(
                                children: [
                                  Icon(
                                    Estilos.iconoCategoria(categoria),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(categoria),
                                ],
                              ),
                            ),
                        ],
                        onChanged: formulario.cambiarCategoria,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Prioridad', style: tema.textTheme.titleSmall),
                          const Spacer(),
                          Text(
                            '${formulario.prioridad} - ${formulario.etiquetaPrioridad}',
                            style: TextStyle(
                              color: Estilos.colorPrioridad(
                                formulario.prioridad,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: formulario.prioridad.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: formulario.etiquetaPrioridad,
                        activeColor: Estilos.colorPrioridad(
                          formulario.prioridad,
                        ),
                        onChanged: formulario.cambiarPrioridad,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        key: const Key('casilla_terminos'),
                        value: formulario.aceptaTerminos,
                        onChanged: formulario.cambiarTerminos,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Confirmo que la informacion es veraz',
                        ),
                        subtitle: const Text(
                          'Acepto los terminos de uso de EcoTrack & RutaSegura.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('boton_guardar'),
                        // Bloqueado hasta aceptar los terminos.
                        onPressed: formulario.puedeEnviar ? _enviar : null,
                        icon: formulario.guardando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Guardar reporte'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      if (!formulario.aceptaTerminos) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Acepta los terminos para habilitar el boton.',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
