import '../../domain/entities/reporte.dart';

/// Modulo 1 y Modulo 3 - Capa `data`.
///
/// Modelo de persistencia del reporte: serializacion `toMap` / `fromMap`
/// hacia y desde SQLite. Extiende a la entidad de dominio, de modo que la
/// capa de presentacion siempre recibe entidades puras (`Reporte`) y nunca
/// conoce las claves de la base de datos.
class ReporteModel extends Reporte {
  ReporteModel({
    required super.id,
    required super.codigo,
    required super.titulo,
    required super.detalle,
    required super.categoria,
    required super.prioridad,
    required super.registradoEn,
    super.sincronizado,
  });

  /// Columnas canonicas de la tabla `reportes`.
  static const List<String> columnas = [
    'id',
    'codigo',
    'titulo',
    'detalle',
    'categoria',
    'prioridad',
    'registrado_en',
    'sincronizado',
  ];

  /// Serializa a la fila que se inserta/actualiza en la tabla.
  Map<String, Object?> toMap() => {
        'id': id,
        'codigo': codigo,
        'titulo': titulo,
        'detalle': detalle,
        'categoria': categoria,
        'prioridad': prioridad,
        'registrado_en': registradoEn.millisecondsSinceEpoch,
        'sincronizado': sincronizado ? 1 : 0,
      };

  /// Reconstruye el modelo desde una fila devuelta por `Database.query(...)`.
  factory ReporteModel.fromMap(Map<String, Object?> mapa) => ReporteModel(
        id: mapa['id']! as String,
        codigo: mapa['codigo']! as String,
        titulo: mapa['titulo']! as String,
        detalle: mapa['detalle']! as String,
        categoria: mapa['categoria']! as String,
        prioridad: (mapa['prioridad']! as num).toInt(),
        registradoEn:
            DateTime.fromMillisecondsSinceEpoch((mapa['registrado_en']! as num).toInt()),
        sincronizado: ((mapa['sincronizado'] as num?) ?? 0) == 1,
      );

  /// Convierte una entidad de dominio en su representacion persistible.
  factory ReporteModel.deEntidad(Reporte entidad) => ReporteModel(
        id: entidad.id,
        codigo: entidad.codigo,
        titulo: entidad.titulo,
        detalle: entidad.detalle,
        categoria: entidad.categoria,
        prioridad: entidad.prioridad,
        registradoEn: entidad.registradoEn,
        sincronizado: entidad.sincronizado,
      );
}
