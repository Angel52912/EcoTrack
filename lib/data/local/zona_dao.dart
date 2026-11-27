import 'package:sqflite/sqflite.dart';

/// Modulo 3 - Patron DAO para el catalogo de zonas.
class ZonaDao {
  ZonaDao(this._base);

  final Future<Database> Function() _base;

  static const String tabla = 'zonas';

  static const List<String> columnas = [
    'id',
    'nombre',
    'ruta',
    'riesgo',
    'entregas',
    'tipo_icono',
    'lugar',
  ];

  /// Lectura con columnas explicitas y orden por riesgo descendente.
  Future<List<Map<String, Object?>>> consultar({int limite = 100}) async {
    final db = await _base();
    return db.query(
      tabla,
      columns: columnas,
      orderBy: 'riesgo DESC, entregas DESC',
      limit: limite,
    );
  }

  /// Reemplaza el catalogo completo en una sola transaccion.
  Future<void> reemplazar(List<Map<String, Object?>> zonas) async {
    final db = await _base();
    await db.transaction((txn) async {
      await txn.delete(tabla);
      for (final zona in zonas) {
        await txn.insert(tabla, zona);
      }
    });
  }
}
