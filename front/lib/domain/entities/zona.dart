/// Tipo de lugar que cubre una zona. La capa `presentation` lo usa para
/// elegir la ilustracion que la representa.
enum TipoLugar {
  centro,
  industrial,
  parque,
  vialidad,
  mercado,
  residencial,
  puerto,
  aeropuerto,
  universidad,
}

/// Capa `domain` - Zona / ruta del catalogo que se muestra en la grilla.
class Zona {
  /// Niveles de riesgo (el dominio trabaja con 1..4).
  static const List<String> nivelesRiesgo = [
    'Baja',
    'Media',
    'Alta',
    'Critica',
  ];

  /// Tipos de icono (la capa `presentation` los traduce a `IconData`).
  static const int tipoRuta = 0;
  static const int tipoCamion = 1;
  static const int tipoPaquete = 2;
  static const int tipoAlerta = 3;

  Zona({
    required String id,
    required String nombre,
    required String ruta,
    required int riesgo,
    required int entregasPendientes,
    required int tipoIcono,
    TipoLugar lugar = TipoLugar.residencial,
  }) : _id = id,
       _lugar = lugar,
       _nombre = nombre,
       _ruta = ruta,
       _riesgo = riesgo,
       _entregasPendientes = entregasPendientes,
       _tipoIcono = tipoIcono,
       assert(nombre.trim().length >= 3, 'Nombre demasiado corto'),
       assert(riesgo >= 1 && riesgo <= 4, 'Riesgo fuera de 1..4'),
       assert(entregasPendientes >= 0, 'Entregas negativas'),
       assert(tipoIcono >= 0 && tipoIcono <= 3, 'Icono desconocido');

  final String _id;
  final String _nombre;
  final String _ruta;
  final int _riesgo;
  final int _entregasPendientes;
  final int _tipoIcono;
  final TipoLugar _lugar;

  String get id => _id;
  String get nombre => _nombre;
  String get ruta => _ruta;
  int get riesgo => _riesgo;
  int get entregasPendientes => _entregasPendientes;
  int get tipoIcono => _tipoIcono;
  TipoLugar get lugar => _lugar;

  String get etiquetaRiesgo => nivelesRiesgo[_riesgo - 1];

  /// Requiere atencion si el riesgo es Alta/Critica o hay mas de 10 entregas.
  bool get requiereAtencion => _riesgo >= 3 || _entregasPendientes > 10;

  @override
  bool operator ==(Object other) => other is Zona && other._id == _id;

  @override
  int get hashCode => _id.hashCode;
}
