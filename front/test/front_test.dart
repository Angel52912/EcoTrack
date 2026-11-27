import 'package:ecotrack_front/data/repositorio_memoria.dart';
import 'package:ecotrack_front/domain/entities/reporte.dart';
import 'package:ecotrack_front/domain/entities/zona.dart';
import 'package:ecotrack_front/domain/validadores/reglas_reporte.dart';
import 'package:ecotrack_front/presentation/views/ilustraciones.dart';
import 'package:ecotrack_front/presentation/controllers/catalogo_controller.dart';
import 'package:ecotrack_front/presentation/controllers/formulario_controller.dart';
import 'package:ecotrack_front/presentation/controllers/reporte_controller.dart';
import 'package:ecotrack_front/presentation/views/ecotrack_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Reporte _reporte(String id, {String categoria = 'Ruta', int prioridad = 3, bool sincronizado = false}) =>
    Reporte(
      id: id,
      codigo: 'EC-2026-AB',
      titulo: 'Reporte $id de prueba',
      detalle: 'Detalle suficientemente largo',
      categoria: categoria,
      prioridad: prioridad,
      registradoEn: DateTime(2026, 1, 1),
      sincronizado: sincronizado,
    );

void main() {
  group('ReglasReporte (RegExp)', () {
    test('Arrange: codigos | Act: validar | Assert: solo EC-0000-XX es valido', () {
      expect(ReglasReporte.validarCodigo('EC-2026-AL'), isNull);
      expect(ReglasReporte.validarCodigo('ec-2026-al'), isNotNull);
      expect(ReglasReporte.validarCodigo('EC-26-AL'), isNotNull);
      expect(ReglasReporte.validarCodigo(''), isNotNull);
    });

    test('Arrange: titulo y detalle cortos | Act: validar | Assert: error', () {
      expect(ReglasReporte.validarTitulo('Hola'), isNotNull);
      expect(ReglasReporte.validarTitulo('Bache en ruta'), isNull);
      expect(ReglasReporte.validarDetalle('corto'), isNotNull);
      expect(ReglasReporte.validarDetalle('Descripcion de diez o mas'), isNull);
    });
  });

  group('ReporteController', () {
    test('Arrange: reportes mixtos | Act: filtrar | Assert: criticos primero y filtro', () async {
      final repo = RepositorioMemoria(
        latencia: Duration.zero,
        reportes: [
          _reporte('a', prioridad: 2),
          _reporte('b', categoria: 'Carga', prioridad: 5),
          _reporte('c', prioridad: 4, sincronizado: true),
        ],
        zonas: const [],
      );
      final c = ReporteController(repositorio: repo);
      await c.cargar();

      expect(c.reportesFiltrados.first.esCritico, isTrue);
      expect(c.totalPendientes, 2);
      c.filtrarPorCategoria('Carga');
      expect(c.reportesFiltrados.map((r) => r.id), ['b']);
    });

    test('Arrange: pendientes | Act: sincronizar | Assert: todos sincronizados', () async {
      final repo = RepositorioMemoria(latencia: Duration.zero, reportes: [_reporte('a')], zonas: const []);
      final c = ReporteController(repositorio: repo);
      await c.cargar();

      await c.sincronizar();

      expect(c.totalPendientes, 0);
      expect(c.mensaje, contains('Sincronizados 1'));
    });
  });

  group('CatalogoController', () {
    test('Arrange: catalogo demo | Act: filtrar riesgo 4 | Assert: solo criticas', () async {
      final c = CatalogoController(repositorio: RepositorioMemoria(latencia: Duration.zero));
      await c.cargar();

      c.filtrarPorRiesgo(4);

      expect(c.zonasFiltradas, isNotEmpty);
      expect(c.zonasFiltradas.every((z) => z.riesgo == 4), isTrue);
    });
  });

  group('Ilustraciones', () {
    test('Arrange: lugares y categorias | Act: elegir escena | Assert: cada uno tiene la suya', () {
      expect(Escena.deLugar(TipoLugar.aeropuerto), Escena.aeropuerto);
      expect(Escena.deLugar(TipoLugar.puerto), Escena.puerto);
      expect(Escena.deCategoria('Ruta'), Escena.bache);
      expect(Escena.deCategoria('Seguridad'), Escena.callesNoche);
      expect(Escena.deCategoria('Ambiental'), Escena.reciclaje);
      for (final lugar in TipoLugar.values) {
        expect(Escena.deLugar(lugar).name, lugar.name);
      }
    });

    testWidgets('Arrange: todas las escenas | Act: dibujar | Assert: sin errores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (final escena in Escena.values)
                SizedBox(width: 120, height: 80, child: Ilustracion(escena: escena)),
            ],
          ),
        ),
      );

      expect(find.byType(Ilustracion), findsNWidgets(Escena.values.length));
      expect(tester.takeException(), isNull);
    });
  });

  group('Vistas', () {
    Future<void> montar(WidgetTester tester) async {
      final repo = RepositorioMemoria(latencia: Duration.zero);
      final reportes = ReporteController(repositorio: repo);
      final catalogo = CatalogoController(repositorio: repo);
      await tester.pumpWidget(
        EcoTrackApp(reportes: reportes, catalogo: catalogo, formulario: FormularioController()),
      );
      await reportes.cargar();
      await catalogo.cargar();
      await tester.pumpAndSettle();
    }

    testWidgets('Arrange: app | Act: abrir | Assert: panel con SliverAppBar', (tester) async {
      await montar(tester);

      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.text('Bache profundo en periferico'), findsOneWidget);
    });

    testWidgets('Arrange: catalogo | Act: ir a pestana | Assert: GridView con zonas', (tester) async {
      await montar(tester);

      await tester.tap(find.text('Catalogo').last);
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Centro Historico'), findsOneWidget);
    });

    testWidgets(
        'Arrange: formulario | Act: llenar y aceptar terminos | '
        'Assert: boton bloqueado hasta aceptar y reporte agregado', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Nuevo').last);
      await tester.pumpAndSettle();

      ButtonStyleButton boton() =>
          tester.widget<ButtonStyleButton>(find.byKey(const Key('boton_guardar')));
      expect(boton().onPressed, isNull);

      await tester.enterText(find.byKey(const Key('campo_codigo')), 'EC-2026-ZZ');
      await tester.enterText(find.byKey(const Key('campo_titulo')), 'Arbol caido en la via');
      await tester.enterText(find.byKey(const Key('campo_detalle')), 'Arbol bloquea el carril izquierdo');
      await tester.ensureVisible(find.byKey(const Key('casilla_terminos')));
      await tester.tap(find.byKey(const Key('casilla_terminos')));
      await tester.pump();
      expect(boton().onPressed, isNotNull);

      await tester.ensureVisible(find.byKey(const Key('boton_guardar')));
      await tester.tap(find.byKey(const Key('boton_guardar')));
      await tester.pumpAndSettle();

      expect(find.text('Arbol caido en la via'), findsOneWidget);
    });
  });
}
