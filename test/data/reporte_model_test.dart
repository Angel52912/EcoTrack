import 'package:ecotrack/data/models/reporte_model.dart';
import 'package:ecotrack/data/models/zona_model.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

void main() {
  group('ReporteModel - serializacion toMap / fromMap', () {
    test(
        'Arrange: entidad | Act: toMap | Assert: columnas y tipos correctos',
        () {
      // Arrange
      final reporte = reporteDePrueba(
        id: 'r_map_1',
        codigo: 'EC-2026-MT',
        prioridad: 4,
        sincronizado: true,
      );

      // Act
      final mapa = ReporteModel.deEntidad(reporte).toMap();

      // Assert
      expect(mapa.keys.toList(), ReporteModel.columnas);
      expect(mapa['id'], 'r_map_1');
      expect(mapa['codigo'], 'EC-2026-MT');
      expect(mapa['prioridad'], 4);
      expect(mapa['registrado_en'], isA<int>());
      expect(mapa['sincronizado'], 1);
    });

    test(
        'Arrange: fila de SQLite | Act: fromMap | Assert: reconstruye todo',
        () {
      // Arrange
      final original = reporteDePrueba(
        id: 'r_map_2',
        categoria: 'Ambiental',
        prioridad: 2,
      );

      // Act
      final mapa = ReporteModel.deEntidad(original).toMap();
      final restaurado = ReporteModel.fromMap(mapa);

      // Assert
      expect(restaurado.id, original.id);
      expect(restaurado.codigo, original.codigo);
      expect(restaurado.titulo, original.titulo);
      expect(restaurado.detalle, original.detalle);
      expect(restaurado.categoria, original.categoria);
      expect(restaurado.prioridad, original.prioridad);
      expect(restaurado.registradoEn, original.registradoEn);
      expect(restaurado.sincronizado, original.sincronizado);
      expect(restaurado, original);
    });

    test(
        'Arrange: fila sin la columna sincronizado | Act: fromMap | '
        'Assert: asume pendiente (0)', () {
      // Arrange
      final fila = {
        'id': 'r_map_3',
        'codigo': 'EC-2026-SE',
        'titulo': 'Fila historica de prueba',
        'detalle': 'Detalle de la fila historica suficiente',
        'categoria': 'Ruta',
        'prioridad': 3,
        'registrado_en': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      };

      // Act
      final modelo = ReporteModel.fromMap(fila);

      // Assert
      expect(modelo.sincronizado, isFalse);
      expect(modelo.pendienteDeSincronizar, isTrue);
    });
  });

  group('ZonaModel - serializacion y mapeo de API', () {
    test('Arrange: entidad | Act: toMap/fromMap | Assert: ida y vuelta', () {
      // Arrange
      final zona = Zona(
        id: 'z_7',
        nombre: 'Zona Norte',
        ruta: 'RUTA-N07',
        riesgo: 3,
        entregasPendientes: 11,
        tipoIcono: Zona.tipoPaquete,
        lugar: TipoLugar.puerto,
      );

      // Act
      final mapa = ZonaModel.deEntidad(zona).toMap();
      final restaurada = ZonaModel.fromMap(mapa);

      // Assert
      expect(mapa.keys.toList(), ZonaModel.columnas);
      expect(mapa['entregas'], 11);
      expect(mapa['lugar'], TipoLugar.puerto.index);
      expect(restaurada.nombre, 'Zona Norte');
      expect(restaurada.etiquetaRiesgo, 'Alta');
      expect(restaurada.lugar, TipoLugar.puerto);
      expect(restaurada, zona);
    });

    test(
        'Arrange: fila vieja sin la columna lugar | Act: fromMap | '
        'Assert: asume el lugar por defecto del dominio', () {
      // Arrange: una fila anterior a la migracion v2 no trae `lugar`.
      final fila = ZonaModel.deEntidad(
        Zona(
          id: 'z_old',
          nombre: 'Zona historica',
          ruta: 'RUTA-V1',
          riesgo: 2,
          entregasPendientes: 4,
          tipoIcono: Zona.tipoRuta,
        ),
      ).toMap()
        ..remove('lugar');

      // Act
      final modelo = ZonaModel.fromMap(fila);

      // Assert
      expect(modelo.lugar, TipoLugar.residencial);
    });

    test('Arrange: JSON de la API | Act: desdeApi | Assert: dominio poblado',
        () {
      // Arrange
      final json = {'id': 3, 'albumId': 2, 'title': 'ruta del campo'};

      // Act
      final zona = ZonaModel.desdeApi(json);

      // Assert
      expect(zona.id, 'z_3');
      expect(zona.ruta, 'RUTA-203');
      expect(zona.nombre, 'RUTA DEL CAMPO');
      expect(zona.riesgo, inInclusiveRange(1, 4));
      expect(zona.entregasPendientes, greaterThanOrEqualTo(0));
      // La API no expone tipo de lugar: se reparte de forma determinista.
      expect(TipoLugar.values, contains(zona.lugar));
    });
  });
}
