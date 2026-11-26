import 'package:flutter/material.dart';

import '../controllers/formulario_controller.dart';
import '../controllers/reporte_controller.dart';

/// Modulo 2.2 - Captura validada (`Form` + `GlobalKey<FormState>`).
///
/// Vista pasiva: no valida ni persiste por su cuenta; delega en
/// `ReglasReporte` (dominio) y en los controladores. El boton de envio queda
/// con `onPressed: null` mientras no se acepten los terminos de seguridad
/// (estado deshabilitado de Material 3).
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
  /// Llave global que controla todo el `Form`. Se regenera tras un envio
  /// exitoso para que los campos vuelvan a leer el estado restablecido del
  /// controlador.
  GlobalKey<FormState> _llaveFormulario = GlobalKey<FormState>();

  /// Controlador de desplazamiento liberado en `dispose()` (sin fugas).
  final ScrollController _desplazamiento = ScrollController();

  bool _enviando = false;

  Future<void> _registrar() async {
    final formulario = widget.formulario;
    final estado = _llaveFormulario.currentState;

    // 1) Validaciones con RegExp (dominio) antes de tocar el repositorio.
    if (estado == null || !estado.validate()) return;

    // 2) Clausula de inmutabilidad: sin terminos aceptados no se envia.
    if (!formulario.puedeEnviar) return;

    final reporte = formulario.construirReporte();
    if (reporte == null) return;

    setState(() => _enviando = true);
    final guardado = await widget.reportes.agregar(reporte);
    if (!mounted) return;

    setState(() => _enviando = false);
    if (guardado) {
      formulario.restablecer();
      // Remonta el `Form` para limpiar visualmente la captura.
      setState(() => _llaveFormulario = GlobalKey<FormState>());
      widget.onGuardado();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte ${reporte.codigo} guardado en SQLite'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formulario = widget.formulario;
    final esAncho = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte de campo')),
      body: ListenableBuilder(
        listenable: formulario,
        builder: (context, _) {
          return SingleChildScrollView(
            controller: _desplazamiento,
            padding: EdgeInsets.all(esAncho ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _llaveFormulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Los campos marcados con * son obligatorios. '
                        'El codigo usa el formato EC-2026-AL.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // ---- Codigo de identificacion (RegEx) --------------
                      TextFormField(
                        key: const Key('campo_codigo'),
                        initialValue: formulario.codigo.isEmpty
                            ? null
                            : formulario.codigo,
                        decoration: const InputDecoration(
                          labelText: 'Codigo *',
                          hintText: 'EC-2026-AL',
                          prefixIcon: Icon(Icons.qr_code_2_rounded),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: formulario.asignarCodigo,
                        validator: formulario.validarCodigo,
                      ),
                      const SizedBox(height: 16),

                      // ---- Titulo ----------------------------------------
                      TextFormField(
                        key: const Key('campo_titulo'),
                        initialValue:
                            formulario.titulo.isEmpty ? null : formulario.titulo,
                        decoration: const InputDecoration(
                          labelText: 'Titulo *',
                          hintText: 'Fuga en tanque de agua',
                          prefixIcon: Icon(Icons.title_rounded),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: formulario.asignarTitulo,
                        validator: formulario.validarTitulo,
                      ),
                      const SizedBox(height: 16),

                      // ---- Detalle ---------------------------------------
                      TextFormField(
                        key: const Key('campo_detalle'),
                        initialValue:
                            formulario.detalle.isEmpty ? null : formulario.detalle,
                        maxLines: 4,
                        maxLength: 400,
                        decoration: const InputDecoration(
                          labelText: 'Detalle de campo *',
                          hintText: 'Describe que ocurrio, donde y cuando...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: formulario.asignarDetalle,
                        validator: formulario.validarDetalle,
                      ),
                      const SizedBox(height: 16),

                      // ---- Categoria --------------------------------------
                      DropdownButtonFormField<String>(
                        // La clave incluye la categoria para que el campo se
                        // remonte al restablecer el formulario.
                        key: Key('campo_categoria_${formulario.categoria}'),
                        initialValue: formulario.categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final categoria in formulario.categorias)
                            DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            ),
                        ],
                        onChanged: formulario.asignarCategoria,
                      ),
                      const SizedBox(height: 16),

                      // ---- Prioridad (slider observable) -----------------
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prioridad: ${formulario.prioridad} '
                                  '(${_etiqueta(formulario.prioridad)})',
                                  key: const Key('etiqueta_prioridad'),
                                ),
                                Slider(
                                  value: formulario.prioridad.toDouble(),
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: _etiqueta(formulario.prioridad),
                                  onChanged: (valor) =>
                                      formulario.asignarPrioridad(valor.round()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ---- Terminos de seguridad (clausula Material 3) ----
                      CheckboxListTile(
                        key: const Key('terminos_seguridad'),
                        value: formulario.aceptaTerminos,
                        onChanged: formulario.asignarTerminos,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Acepto los terminos de seguridad y el protocolo '
                          'de operacion en campo',
                        ),
                        subtitle: const Text(
                          'Sin esta aceptacion el envio permanece bloqueado',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ---- Boton de envio bloqueado ----------------------
                      FilledButton(
                        key: const Key('boton_registrar'),
                        onPressed: (formulario.puedeEnviar && !_enviando)
                            ? _registrar
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _enviando ? 'Guardando...' : 'Registrar reporte',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formulario.puedeEnviar
                            ? 'Listo para registrar en la base local (.db)'
                            : 'Activa la casilla de terminos para habilitar el envio',
                        key: const Key('mensaje_estado_envio'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
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

  String _etiqueta(int prioridad) => switch (prioridad) {
        5 => 'Critica',
        4 => 'Alta',
        3 => 'Media',
        2 => 'Baja',
        _ => 'Informativa',
      };
}
