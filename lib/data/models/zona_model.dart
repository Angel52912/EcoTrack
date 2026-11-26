import '../../domain/entities/zona.dart';

/// Modulo 1 y Modulo 3 - Capa `data`.
///
/// Modelo de persistencia de las zonas del catalogo (`toMap` / `fromMap`).
class ZonaModel extends Zona {
  ZonaModel({
    required super.id,
    required super.nombre,
    required super.ruta,
    required super.riesgo,
    required super.entregasPendientes,
    required super.tipoIcono,
  });

  static const List<String> columnas = [
    'id',
    'nombre',
    'ruta',
    'riesgo',
    'entregas',
    'tipo_icono',
  ];

  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'ruta': ruta,
        'riesgo': riesgo,
        'entregas': entregasPendientes,
        'tipo_icono': tipoIcono,
      };

  factory ZonaModel.fromMap(Map<String, Object?> mapa) => ZonaModel(
        id: mapa['id']! as String,
        nombre: mapa['nombre']! as String,
        ruta: mapa['ruta']! as String,
        riesgo: (mapa['riesgo']! as num).toInt(),
        entregasPendientes: (mapa['entregas']! as num).toInt(),
        tipoIcono: (mapa['tipo_icono']! as num).toInt(),
      );

  factory ZonaModel.deEntidad(Zona entidad) => ZonaModel(
        id: entidad.id,
        nombre: entidad.nombre,
        ruta: entidad.ruta,
        riesgo: entidad.riesgo,
        entregasPendientes: entidad.entregasPendientes,
        tipoIcono: entidad.tipoIcono,
      );

  /// Mapea un objeto JSON proveniente de la API REST publica a una zona.
  ///
  /// La API de referencia (`jsonplaceholder.typicode.com`) devuelve albumes de
  /// fotos; aqui se traduce ese esquema al dominio de EcoTrack.
  factory ZonaModel.desdeApi(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final album = (json['albumId'] as num?)?.toInt() ?? 1;
    final titulo = (json['title'] as String?) ?? 'Zona $id';
    final nombre = titulo.isEmpty ? 'Zona $id' : titulo.toUpperCase();

    return ZonaModel(
      id: 'z_$id',
      nombre: nombre.length > 40 ? nombre.substring(0, 40) : nombre,
      ruta: 'RUTA-$album${id.toString().padLeft(2, '0')}',
      riesgo: (id % 4) + 1,
      entregasPendientes: (id * 7) % 15,
      tipoIcono: id % 4,
    );
  }
}
