/// Modulo 1 - Capa `domain`.
///
/// Entidad inmutable que representa una zona / ruta del catalogo
/// bidimensional que se muestra en la grilla de la aplicacion.
class Zona {
  /// Niveles de riesgo (indice 0..3, el dominio trabaja con 1..4).
  static const List<String> nivelesRiesgo = ['Baja', 'Media', 'Alta', 'Critica'];

  /// Tipos de icono conocidos por el negocio (0..3). La capa `presentation`
  /// es la unica que traduce este indice a un `IconData` de Material.
  static const int tipoRuta = 0;
  static const int tipoCamion = 1;
  static const int tipoPaquete = 2;
  static const int tipoAlerta = 3;

  final String _id;
  final String _nombre;
  final String _ruta;
  final int _riesgo;
  final int _entregasPendientes;
  final int _tipoIcono;

  Zona({
    required String id,
    required String nombre,
    required String ruta,
    required int riesgo,
    required int entregasPendientes,
    required int tipoIcono,
  })  : _id = id,
        _nombre = nombre,
        _ruta = ruta,
        _riesgo = riesgo,
        _entregasPendientes = entregasPendientes,
        _tipoIcono = tipoIcono,
        // Aserciones de integridad en la lista de inicializacion.
        assert(id.trim().isNotEmpty, 'El id de la zona no puede estar vacio'),
        assert(
          nombre.trim().length >= 3,
          'El nombre de la zona es demasiado corto',
        ),
        assert(ruta.trim().isNotEmpty, 'La ruta no puede estar vacia'),
        assert(
          riesgo >= 1 && riesgo <= 4,
          'El riesgo debe estar entre 1 (Baja) y 4 (Critica)',
        ),
        assert(
          entregasPendientes >= 0,
          'Las entregas pendientes no pueden ser negativas',
        ),
        assert(
          tipoIcono >= 0 && tipoIcono <= 3,
          'Tipo de icono desconocido: $tipoIcono',
        );

  String get id => _id;
  String get nombre => _nombre;
  String get ruta => _ruta;
  int get riesgo => _riesgo;
  int get entregasPendientes => _entregasPendientes;
  int get tipoIcono => _tipoIcono;

  // ---------------------------------------------------------------------------
  // Getters computados.
  // ---------------------------------------------------------------------------
  String get etiquetaRiesgo => nivelesRiesgo[_riesgo - 1];

  /// La zona requiere atencion inmediata del supervisor si su riesgo es
  /// alto/critico o si acumula mas de 10 entregas pendientes.
  bool get requiereAtencion => _riesgo >= 3 || _entregasPendientes > 10;

  /// Percentual de avance estimado (0..1) segun entregas resueltas.
  double get avance => _entregasPendientes == 0 ? 1.0 : 1 / (_entregasPendientes + 1);

  @override
  bool operator ==(Object other) => other is Zona && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Zona($_nombre, riesgo=$etiquetaRiesgo)';
}
