import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/zona.dart';
import '../models/zona_model.dart';

/// Modulo 3 - Capa `data`, fuente local.
///
/// Base de datos embebida `.db` (Offline-First). Todas las carpetas del
/// esquema se crean aqui; el resto de la app solo conoce el patron DAO.
class AppDatabase {
  AppDatabase._();

  static const String nombreArchivo = 'ecotrack.db';
  static const int version = 1;

  static Future<Database>? _cache;

  /// Devuelve la instancia unica de la base (se abre una sola vez).
  static Future<Database> instancia() => _cache ??= _abrir();

  static Future<Database> _abrir() async {
    final ruta = p.join(await getDatabasesPath(), nombreArchivo);
    return openDatabase(
      ruta,
      version: version,
      onCreate: crearEsquema,
    );
  }

  /// Crea las tablas y siembra el catalogo inicial de zonas para que la
  /// aplicacion tenga contenido aun sin conexion desde el primer arranque.
  static Future<void> crearEsquema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reportes (
        id TEXT PRIMARY KEY NOT NULL,
        codigo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        detalle TEXT NOT NULL,
        categoria TEXT NOT NULL,
        prioridad INTEGER NOT NULL,
        registrado_en INTEGER NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reportes_categoria ON reportes(categoria)',
    );
    await db.execute('''
      CREATE TABLE zonas (
        id TEXT PRIMARY KEY NOT NULL,
        nombre TEXT NOT NULL,
        ruta TEXT NOT NULL,
        riesgo INTEGER NOT NULL,
        entregas INTEGER NOT NULL,
        tipo_icono INTEGER NOT NULL
      )
    ''');

    for (final zona in ZonaSemillas.lista) {
      await db.insert('zonas', ZonaModel.deEntidad(zona).toMap());
    }
  }

  /// Cierra el cache (util en pruebas y en `dispose` del ciclo de vida).
  static Future<void> cerrar() async {
    final db = _cache;
    _cache = null;
    if (db != null) (await db).close();
  }
}

/// Catalogo semilla: garantiza datos locales iniciales (Offline-First).
class ZonaSemillas {
  static final List<Zona> lista = [
    Zona(
      id: 'z_1',
      nombre: 'Centro Logistico Norte',
      ruta: 'RUTA-N01',
      riesgo: 1,
      entregasPendientes: 3,
      tipoIcono: Zona.tipoCamion,
    ),
    Zona(
      id: 'z_2',
      nombre: 'Corredor Rural Sur',
      ruta: 'RUTA-S07',
      riesgo: 3,
      entregasPendientes: 12,
      tipoIcono: Zona.tipoRuta,
    ),
    Zona(
      id: 'z_3',
      nombre: 'Tunel Subterraneo 4',
      ruta: 'RUTA-T04',
      riesgo: 4,
      entregasPendientes: 8,
      tipoIcono: Zona.tipoAlerta,
    ),
    Zona(
      id: 'z_4',
      nombre: 'Mercado Municipal',
      ruta: 'RUTA-M12',
      riesgo: 2,
      entregasPendientes: 5,
      tipoIcono: Zona.tipoPaquete,
    ),
    Zona(
      id: 'z_5',
      nombre: 'Zona Agricola Este',
      ruta: 'RUTA-E09',
      riesgo: 2,
      entregasPendientes: 14,
      tipoIcono: Zona.tipoRuta,
    ),
    Zona(
      id: 'z_6',
      nombre: 'Deposito Industrial',
      ruta: 'RUTA-I02',
      riesgo: 1,
      entregasPendientes: 0,
      tipoIcono: Zona.tipoCamion,
    ),
  ];
}
