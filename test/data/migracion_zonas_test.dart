import 'dart:io';

import 'package:ecotrack/data/local/app_database.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
      'Arrange: base v1 sin la columna lugar | Act: reabrir en v2 con '
      'onUpgrade | Assert: ALTER TABLE aplicado y filas legibles', () async {
    // Arrange: archivo temporal que simula una instalacion existente.
    final dir = await Directory.systemTemp.createTemp('ecotrack_migra');
    final ruta = p.join(dir.path, 'vieja.db');

    // BD version 1 (esquema anterior: sin `lugar`).
    final v1 = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
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
          await db.insert('zonas', {
            'id': 'z_vieja',
            'nombre': 'Zona pre-migracion',
            'ruta': 'RUTA-V1',
            'riesgo': 2,
            'entregas': 5,
            'tipo_icono': 0,
          });
        },
      ),
    );
    await v1.close();

    // Act: reabrir como lo hace la app (version 2 + onUpgrade).
    final v2 = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: AppDatabase.version,
        onCreate: AppDatabase.crearEsquema,
        onUpgrade: AppDatabase.migrar,
      ),
    );

    // Assert: la fila vieja sigue ahi y ahora tiene `lugar` por defecto.
    final viejas = await v2.query('zonas', where: 'id = ?', whereArgs: [
      'z_vieja',
    ]);
    expect(viejas, hasLength(1),
        reason: 'La migracion no debe perder las filas existentes');
    expect(viejas.single['lugar'], TipoLugar.residencial.index);

    // Assert: la columna nueva acepta escribir cualquier lugar.
    await v2.insert('zonas', {
      'id': 'z_nueva',
      'nombre': 'Zona post-migracion',
      'ruta': 'RUTA-V2',
      'riesgo': 4,
      'entregas': 1,
      'tipo_icono': 3,
      'lugar': TipoLugar.puerto.index,
    });
    final nuevas = await v2.query('zonas', where: 'id = ?', whereArgs: [
      'z_nueva',
    ]);
    expect(nuevas.single['lugar'], TipoLugar.puerto.index);

    expect(await v2.getVersion(), AppDatabase.version);
    await v2.close();

    // Limpieza del archivo temporal de la prueba.
    await dir.delete(recursive: true);
  });
}
