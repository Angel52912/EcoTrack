import 'package:sqflite/sqflite.dart';

/// Modulo 3 - Patron DAO (Data Access Object).
///
/// Unica capa autorizada a escribir SQL. Reglas de seguridad aplicadas en
/// todas las consultas:
///  * `columns:` explicito -> nunca `SELECT *`.
///  * `where:` con `?` y `whereArgs:` posicional -> imposible de inyectar SQL.
class ReporteDao {
  ReporteDao(this._base);

  /// Proveedor perezoso de la base (permite probar el DAO con SQLite en memoria).
  final Future<Database> Function() _base;

  static const String tabla = 'reportes';

  /// Columnas explicitas seleccionadas en cada lectura.
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

  /// Inserta o reemplaza un reporte (conflictos resueltos por `id`).
  Future<int> insertar(Map<String, Object?> registro) async {
    final db = await _base();
    return db.insert(
      tabla,
      registro,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Consulta optimizada: columnas explicitas + filtro parametrico opcional.
  Future<List<Map<String, Object?>>> consultar({
    String? categoria,
    int limite = 200,
  }) async {
    final db = await _base();
    final hayFiltro = categoria != null && categoria.trim().isNotEmpty;
    return db.query(
      tabla,
      columns: columnas,
      where: hayFiltro ? 'categoria = ?' : null,
      whereArgs: hayFiltro ? [categoria.trim()] : null,
      orderBy: 'prioridad DESC, registrado_en DESC',
      limit: limite,
    );
  }

  /// Cuenta registros respetando el mismo filtro parametrico.
  Future<int> contar({String? categoria}) async {
    final db = await _base();
    final hayFiltro = categoria != null && categoria.trim().isNotEmpty;
    final resultado = await db.query(
      tabla,
      columns: ['COUNT(*) AS total'],
      where: hayFiltro ? 'categoria = ?' : null,
      whereArgs: hayFiltro ? [categoria.trim()] : null,
    );
    return (resultado.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Reportes que aun no han sido sincronizados con la nube.
  Future<List<Map<String, Object?>>> pendientesDeSincronizar() async {
    final db = await _base();
    return db.query(
      tabla,
      columns: columnas,
      where: 'sincronizado = ?',
      whereArgs: const [0],
    );
  }

  /// Elimina por id con parametro posicional (sin concatenar texto).
  Future<int> eliminar(String id) async {
    final db = await _base();
    return db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

  /// Marca un reporte como sincronizado usando igualmente `whereArgs`.
  Future<int> marcarSincronizado(String id) async {
    final db = await _base();
    return db.update(
      tabla,
      const {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
