import '../validadores/reglas_reporte.dart';

/// Capa `domain` - Novedad de campo registrada por un repartidor.
///
/// Inmutable: propiedades privadas, lista de inicializacion, getters
/// computados y `assert` de integridad.
class Reporte {
  static const List<String> categorias = [
    'Ruta',
    'Carga',
    'Seguridad',
    'Ambiental',
  ];

  Reporte({
    required String id,
    required String codigo,
    required String titulo,
    required String detalle,
    required String categoria,
    required int prioridad,
    required DateTime registradoEn,
    bool sincronizado = false,
  }) : _id = id,
       _codigo = codigo,
       _titulo = titulo,
       _detalle = detalle,
       _categoria = categoria,
       _prioridad = prioridad,
       _registradoEn = registradoEn,
       _sincronizado = sincronizado,
       assert(id.trim().isNotEmpty, 'El id no puede estar vacio'),
       assert(ReglasReporte.patronCodigo.hasMatch(codigo), 'Codigo invalido'),
       assert(titulo.trim().length >= 5, 'Titulo demasiado corto'),
       assert(categorias.contains(categoria), 'Categoria fuera del catalogo'),
       assert(prioridad >= 1 && prioridad <= 5, 'Prioridad fuera de 1..5');

  final String _id;
  final String _codigo;
  final String _titulo;
  final String _detalle;
  final String _categoria;
  final int _prioridad;
  final DateTime _registradoEn;
  final bool _sincronizado;

  String get id => _id;
  String get codigo => _codigo;
  String get titulo => _titulo;
  String get detalle => _detalle;
  String get categoria => _categoria;
  int get prioridad => _prioridad;
  DateTime get registradoEn => _registradoEn;
  bool get sincronizado => _sincronizado;

  /// Critico cuando la prioridad es 4 (Alta) o 5 (Critica).
  bool get esCritico => _prioridad >= 4;

  bool get pendienteDeSincronizar => !_sincronizado;

  String get etiquetaPrioridad => etiquetaDe(_prioridad);

  String get estadoSincronizacion =>
      _sincronizado ? 'Sincronizado' : 'Pendiente de sincronizar';

  String get resumen => '$_codigo | $_categoria | $etiquetaPrioridad';

  /// Fecha corta dd/mm/aaaa hh:mm (sin dependencias de `intl`).
  String get fechaCorta {
    String dos(int n) => n.toString().padLeft(2, '0');
    final f = _registradoEn;
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  static String etiquetaDe(int prioridad) => switch (prioridad) {
    5 => 'Critica',
    4 => 'Alta',
    3 => 'Media',
    2 => 'Baja',
    _ => 'Informativa',
  };

  Reporte copiarCon({bool? sincronizado}) => Reporte(
    id: _id,
    codigo: _codigo,
    titulo: _titulo,
    detalle: _detalle,
    categoria: _categoria,
    prioridad: _prioridad,
    registradoEn: _registradoEn,
    sincronizado: sincronizado ?? _sincronizado,
  );

  @override
  bool operator ==(Object other) => other is Reporte && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Reporte($resumen)';
}
