import 'package:flutter/foundation.dart';

import '../../domain/entities/reporte.dart';
import '../../domain/validadores/reglas_reporte.dart';

/// Modulo 2.2 y 2.3 - Estado observable del formulario de alta.
///
/// La vista jamas calcula: solo escribe mediante los `onChanged` y lee el
/// estado (`puedeEnviar`) dentro de un `ListenableBuilder`. Las validaciones
/// con `RegExp` viven en el dominio (`ReglasReporte`).
class FormularioController extends ChangeNotifier {
  String _codigo = '';
  String _titulo = '';
  String _detalle = '';
  String _categoria = Reporte.categorias.first;
  int _prioridad = 3;
  bool _aceptaTerminos = false;

  String get codigo => _codigo;
  String get titulo => _titulo;
  String get detalle => _detalle;
  String get categoria => _categoria;
  int get prioridad => _prioridad;
  bool get aceptaTerminos => _aceptaTerminos;

  /// Regla Material 3: el boton de envio queda `onPressed: null`
  /// (estado deshabilitado) mientras no se acepten los terminos de seguridad.
  bool get puedeEnviar => _aceptaTerminos;

  List<String> get categorias => Reporte.categorias;

  // ---------------------------------------------------------------------------
  // Mutaciones observables
  // ---------------------------------------------------------------------------
  void asignarCodigo(String valor) {
    _codigo = valor.trim().toUpperCase();
    notifyListeners();
  }

  void asignarTitulo(String valor) {
    _titulo = valor.trim();
    notifyListeners();
  }

  void asignarDetalle(String valor) {
    _detalle = valor.trim();
    notifyListeners();
  }

  void asignarCategoria(String? valor) {
    if (valor == null) return;
    _categoria = valor;
    notifyListeners();
  }

  void asignarPrioridad(int valor) {
    _prioridad = valor.clamp(1, 5);
    notifyListeners();
  }

  void asignarTerminos(bool? valor) {
    _aceptaTerminos = valor ?? false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Validaciones reutilizadas por el `Form` (validator: ReglasReporte...)
  // ---------------------------------------------------------------------------
  String? validarCodigo(String? valor) => ReglasReporte.validarCodigo(valor);
  String? validarTitulo(String? valor) => ReglasReporte.validarTitulo(valor);
  String? validarDetalle(String? valor) => ReglasReporte.validarDetalle(valor);

  /// Construye la entidad del negocio solo si todas las reglas pasan.
  /// Devuelve `null` cuando la captura es invalida.
  Reporte? construirReporte() {
    if (!puedeEnviar) return null;
    if (ReglasReporte.validarCodigo(_codigo) != null) return null;
    if (ReglasReporte.validarTitulo(_titulo) != null) return null;
    if (ReglasReporte.validarDetalle(_detalle) != null) return null;

    return Reporte(
      id: 'r_${DateTime.now().microsecondsSinceEpoch}',
      codigo: _codigo,
      titulo: _titulo,
      detalle: _detalle,
      categoria: _categoria,
      prioridad: _prioridad,
      registradoEn: DateTime.now(),
      sincronizado: false,
    );
  }

  /// Reinicia la captura tras un envio exitoso.
  void restablecer() {
    _codigo = '';
    _titulo = '';
    _detalle = '';
    _categoria = Reporte.categorias.first;
    _prioridad = 3;
    _aceptaTerminos = false;
    notifyListeners();
  }

  /// Sin recursos pesados: `dispose` libera unicamente al `ChangeNotifier`.
  @override
  void dispose() {
    super.dispose();
  }
}
