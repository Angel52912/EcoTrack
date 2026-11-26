import '../validadores/reglas_reporte.dart';

/// Modulo 1 - Capa `domain`.
///
/// Entidad inmutable del negocio. Cumple con:
///  * listas de inicializacion (`: _campo = valor`),
///  * propiedades privadas (`_`),
///  * getters computados,
///  * validaciones en tiempo de desarrollo mediante `assert`.
class Reporte {
  /// Catalogo cerrado de categorias que el negocio reconoce.
  static const List<String> categorias = [
    'Ruta',
    'Carga',
    'Seguridad',
    'Ambiental',
  ];

  final String _id;
  final String _codigo;
  final String _titulo;
  final String _detalle;
  final String _categoria;
  final int _prioridad;
  final DateTime _registradoEn;
  final bool _sincronizado;

  Reporte({
    required String id,
    required String codigo,
    required String titulo,
    required String detalle,
    required String categoria,
    required int prioridad,
    required DateTime registradoEn,
    bool sincronizado = false,
  })  : _id = id,
        _codigo = codigo,
        _titulo = titulo,
        _detalle = detalle,
        _categoria = categoria,
        _prioridad = prioridad,
        _registradoEn = registradoEn,
        _sincronizado = sincronizado,
        // Aserciones en la lista de inicializacion: solo existen en modo
        // desarrollo/debug (`flutter test`, `flutter run`), validando la
        // integridad de la entidad al instanciarse.
        assert(id.trim().isNotEmpty, 'El id del reporte no puede estar vacio'),
        assert(
          ReglasReporte.patronCodigo.hasMatch(codigo),
          'Codigo invalido: se espera el formato EC-0000-XX',
        ),
        assert(
          titulo.trim().length >= 5,
          'El titulo debe tener al menos 5 caracteres',
        ),
        assert(
          categorias.contains(categoria),
          'Categoria "$categoria" fuera del catalogo permitido',
        ),
        assert(
          prioridad >= 1 && prioridad <= 5,
          'La prioridad debe estar entre 1 y 5',
        ),
        assert(
          !registradoEn.isAfter(DateTime.now().add(const Duration(days: 1))),
          'La fecha de registro no puede estar en el futuro',
        );

  // ---------------------------------------------------------------------------
  // Accesores de lectura (la instancia nunca muta: inmutabilidad).
  // ---------------------------------------------------------------------------
  String get id => _id;
  String get codigo => _codigo;
  String get titulo => _titulo;
  String get detalle => _detalle;
  String get categoria => _categoria;
  int get prioridad => _prioridad;
  DateTime get registradoEn => _registradoEn;
  bool get sincronizado => _sincronizado;

  // ---------------------------------------------------------------------------
  // Getters computados (logica derivada del negocio, nunca datos crudos).
  // ---------------------------------------------------------------------------
  /// Un reporte es critico cuando su prioridad es 4 o 5.
  bool get esCritico => _prioridad >= 4;

  /// Estrategia Offline-First: true cuando aun no ha viajado a la nube.
  bool get pendienteDeSincronizar => !_sincronizado;

  /// Etiqueta humana de la prioridad numerica.
  String get etiquetaPrioridad => switch (_prioridad) {
        5 => 'Critica',
        4 => 'Alta',
        3 => 'Media',
        2 => 'Baja',
        _ => 'Informativa',
      };

  /// Antiguedad del reporte desde su registro en campo.
  Duration get antiguedad => DateTime.now().difference(_registradoEn);

  /// Texto compacto usado por la UI en listas y notificaciones.
  String get resumen => '$_codigo | $_categoria | $etiquetaPrioridad';

  /// Indice para ordenar de mayor a menor urgencia.
  int get pesoDeOrden => esCritico ? (10 - _prioridad) : _prioridad;

  @override
  bool operator ==(Object other) => other is Reporte && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Reporte($resumen)';
}
