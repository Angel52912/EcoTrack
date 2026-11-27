import 'package:flutter/foundation.dart';

import '../../domain/entities/reporte.dart';

/// Estado del formulario de nuevo reporte: categoria, prioridad y aceptacion
/// de terminos. Los textos viven en los `TextEditingController` de la vista.
class FormularioController extends ChangeNotifier {
  String _categoria = Reporte.categorias.first;
  int _prioridad = 3;
  bool _aceptaTerminos = false;
  bool _guardando = false;

  String get categoria => _categoria;
  int get prioridad => _prioridad;
  bool get aceptaTerminos => _aceptaTerminos;
  bool get guardando => _guardando;

  /// El boton de envio queda bloqueado (`onPressed: null`) hasta aceptar
  /// los terminos y mientras se esta guardando.
  bool get puedeEnviar => _aceptaTerminos && !_guardando;

  String get etiquetaPrioridad => Reporte.etiquetaDe(_prioridad);

  void cambiarCategoria(String? categoria) {
    if (categoria == null || !Reporte.categorias.contains(categoria)) return;
    _categoria = categoria;
    notifyListeners();
  }

  void cambiarPrioridad(double valor) {
    final nueva = valor.round().clamp(1, 5);
    if (nueva == _prioridad) return;
    _prioridad = nueva;
    notifyListeners();
  }

  void cambiarTerminos(bool? acepta) {
    _aceptaTerminos = acepta ?? false;
    notifyListeners();
  }

  /// Construye la entidad con los textos ya validados por el `Form`.
  Reporte construir({
    required String codigo,
    required String titulo,
    required String detalle,
  }) {
    final ahora = DateTime.now();
    return Reporte(
      id: 'r_${ahora.microsecondsSinceEpoch}',
      codigo: codigo.trim(),
      titulo: titulo.trim(),
      detalle: detalle.trim(),
      categoria: _categoria,
      prioridad: _prioridad,
      registradoEn: ahora,
    );
  }

  void marcarGuardando(bool valor) {
    _guardando = valor;
    notifyListeners();
  }

  void reiniciar() {
    _categoria = Reporte.categorias.first;
    _prioridad = 3;
    _aceptaTerminos = false;
    _guardando = false;
    notifyListeners();
  }
}
