import 'package:ecotrack/domain/entities/zona.dart';
import 'package:ecotrack/presentation/views/estilos.dart';
import 'package:ecotrack/presentation/views/ilustraciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Escena - traduccion de datos del dominio a ilustracion', () {
    test(
        'Arrange: lugares y categorias | Act: elegir escena | '
        'Assert: cada uno tiene la suya', () {
      // Act / Assert
      expect(Escena.deLugar(TipoLugar.aeropuerto), Escena.aeropuerto);
      expect(Escena.deLugar(TipoLugar.puerto), Escena.puerto);
      expect(Escena.deCategoria('Ruta'), Escena.bache);
      expect(Escena.deCategoria('Seguridad'), Escena.callesNoche);
      expect(Escena.deCategoria('Ambiental'), Escena.reciclaje);
      for (final lugar in TipoLugar.values) {
        expect(Escena.deLugar(lugar).name, lugar.name);
      }
    });

    testWidgets(
        'Arrange: todas las escenas | Act: dibujar | Assert: sin errores',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (final escena in Escena.values)
                SizedBox(
                  width: 120,
                  height: 80,
                  child: Ilustracion(escena: escena),
                ),
            ],
          ),
        ),
      );

      // Assert: 13 escenas pintadas sin excepciones de render.
      expect(find.byType(Ilustracion), findsNWidgets(Escena.values.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Arrange: ilustracion redondeada | Act: pintar en un tarjeta | '
        'Assert: respeta el radio de esquina', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 100,
                child: Ilustracion(escena: Escena.parque, radio: 0),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Ilustracion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Estilos - traduccion de indices a color e icono', () {
    test('Act: colorRiesgo | Assert: escala 1..4 sin repeticiones', () {
      // Arrange
      final colores = [for (var r = 1; r <= 4; r++) Estilos.colorRiesgo(r)];

      // Assert
      expect(colores.toSet(), hasLength(4),
          reason: 'Cada nivel de riesgo debe tener su propio color');
      expect(Estilos.colorRiesgo(4).toARGB32(), isNot(Estilos.colorRiesgo(1).toARGB32()));
    });

    test('Act: colorPrioridad | Assert: 5 es la mas critica (roja)', () {
      // Assert
      expect(
        Estilos.colorPrioridad(5).toARGB32(),
        Estilos.colorRiesgo(4).toARGB32(),
        reason: 'Prioridad critica comparte el rojo del riesgo critico',
      );
      expect(Estilos.colorPrioridad(1), isNot(Estilos.colorPrioridad(5)));
    });

    test('Act: iconoZona e iconoCategoria | Assert: iconos Material distintos',
        () {
      // Assert
      expect(Estilos.iconoZona(Zona.tipoCamion), Icons.local_shipping_rounded);
      expect(Estilos.iconoZona(Zona.tipoAlerta), Icons.warning_amber_rounded);
      expect(Estilos.iconoCategoria('Carga'), Icons.inventory_rounded);
      expect(Estilos.iconoCategoria('Desconocida'), Icons.route_rounded);
    });

    test('Act: tema(claro/oscuro) | Assert: Material 3 con el mismo seed', () {
      // Act
      final claro = Estilos.tema(Brightness.light);
      final oscuro = Estilos.tema(Brightness.dark);

      // Assert
      expect(claro.useMaterial3, isTrue);
      expect(oscuro.useMaterial3, isTrue);
      expect(claro.brightness, Brightness.light);
      expect(oscuro.brightness, Brightness.dark);
      expect(claro.colorScheme.brightness, Brightness.light);
      expect(oscuro.colorScheme.brightness, Brightness.dark);
      expect(claro.inputDecorationTheme.border, isNotNull);
      expect(oscuro.inputDecorationTheme.border, isNotNull);
    });
  });
}
