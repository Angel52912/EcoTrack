import 'package:ecotrack/domain/entities/reporte.dart';
import 'package:ecotrack/domain/entities/zona.dart';
import 'package:ecotrack/presentation/controllers/catalogo_controller.dart';
import 'package:ecotrack/presentation/controllers/formulario_controller.dart';
import 'package:ecotrack/presentation/controllers/reporte_controller.dart';
import 'package:ecotrack/presentation/views/ecotrack_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

/// Escenario completo: repositorio falso + controladores + app Material 3.
class Escenario {
  Escenario({
    required this.repositorio,
    required this.reportes,
    required this.catalogo,
    required this.formulario,
  });

  final RepositorioFalso repositorio;
  final ReporteController reportes;
  final CatalogoController catalogo;
  final FormularioController formulario;
}

List<Reporte> _reportesSemilla() => [
      reporteDePrueba(
        id: 'r_1',
        codigo: 'EC-2026-AL',
        titulo: 'Fuga en tanque principal',
        categoria: 'Carga',
        prioridad: 5,
      ),
      reporteDePrueba(
        id: 'r_2',
        codigo: 'EC-2026-MT',
        titulo: 'Bache en ruta rural',
        categoria: 'Ruta',
        prioridad: 2,
      ),
      reporteDePrueba(
        id: 'r_3',
        codigo: 'EC-2026-SE',
        titulo: 'Conductor sin elementos',
        categoria: 'Seguridad',
        prioridad: 4,
      ),
    ];

List<Zona> _zonasSemilla() => [
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
    ];

Future<Escenario> preparar(WidgetTester tester) async {
  // Arrange
  final repositorio = RepositorioFalso()
    ..reportes.addAll(_reportesSemilla())
    ..zonas.addAll(_zonasSemilla());

  final reportes = ReporteController(repositorio: repositorio);
  final catalogo = CatalogoController(repositorio: repositorio);
  final formulario = FormularioController();

  await reportes.cargar();
  await catalogo.cargar();

  // Act
  await tester.pumpWidget(
    EcoTrackApp(
      reportes: reportes,
      catalogo: catalogo,
      formulario: formulario,
    ),
  );
  await tester.pumpAndSettle();

  return Escenario(
    repositorio: repositorio,
    reportes: reportes,
    catalogo: catalogo,
    formulario: formulario,
  );
}

Future<void> navegarA(WidgetTester tester, String etiqueta) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(etiqueta),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desplaza el formulario hasta centrar [objetivo] dentro de su scroll.
///
/// A diferencia de `ensureVisible`, aqui el calculo se hace con las cajas ya
/// maquetadas, por lo que es determinista en pantallas pequenas.
Future<void> asegurarVisible(WidgetTester tester, Finder objetivo) async {
  // El unico `SingleChildScrollView` del arbol es el del formulario.
  final scroller = find.byType(SingleChildScrollView);

  for (var intento = 0; intento < 25; intento++) {
    final viewport = tester.getRect(scroller);
    final centro = tester.getRect(objetivo).center;
    if (viewport.contains(centro)) return;
    final dy = centro.dy - viewport.center.dy;
    await tester.drag(scroller, Offset(0, -dy));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Modulo 2 - Vista del panel (Slivers, Wrap y estado desacoplado)', () {
    testWidgets(
        'Arrange: panel cargado | Act: desplazar y tocar un filtro | '
        'Assert: SliverAppBar colapsable, Wrap sin overflow y lista filtrada',
        (tester) async {
      // Arrange
      final escenario = await preparar(tester);

      // Assert de estructura
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(Wrap), findsWidgets);
      expect(find.byType(ListenableBuilder), findsWidgets);
      expect(find.text('Fuga en tanque principal'), findsOneWidget);
      expect(find.text('Bache en ruta rural'), findsOneWidget);

      // Act: filtrar con el chip "Carga".
      await tester.tap(find.widgetWithText(FilterChip, 'Carga'));
      await tester.pumpAndSettle();

      // Assert
      expect(escenario.repositorio.ultimaCategoriaConsultada, 'Carga');
      expect(find.text('Fuga en tanque principal'), findsOneWidget);
      expect(find.text('Bache en ruta rural'), findsNothing);
      expect(find.text('Conductor sin elementos'), findsNothing);
      expect(find.textContaining('Reportes en campo: 1'), findsOneWidget);

      // Act final: desplazar el CustomScrollView para colapsar la
      // SliverAppBar (si existiera RenderFlex Overflow, flutter_test fallaria).
      await tester.drag(
        find.byKey(const Key('panel_scroll')),
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();

      // Assert final: el listado filtrado permanece visible tras el scroll.
      expect(find.text('Fuga en tanque principal'), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets(
        'Arrange: tarjeta visible | Act: tocar el boton eliminar | '
        'Assert: la tarjeta desaparece del listado', (tester) async {
      // Arrange
      final escenario = await preparar(tester);
      expect(find.byKey(const Key('tarjeta_r_2')), findsOneWidget);

      // Act
      await tester.tap(find.descendant(
        of: find.byKey(const Key('tarjeta_r_2')),
        matching: find.byIcon(Icons.delete_outline),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('tarjeta_r_2')), findsNothing);
      expect(escenario.repositorio.reportes, hasLength(2));
    });
  });

  group('Modulo 2.2 - Formulario validado con RegExp y terminos', () {
    testWidgets(
        'Arrange: formulario vacio | Act: intentar enviar sin terminos | '
        'Assert: onPressed null hasta aceptar; RegEx bloquea el codigo malo',
        (tester) async {
      // Arrange
      final escenario = await preparar(tester);
      await navegarA(tester, 'Nuevo');

      // Assert 1: Material 3 bloquea el boton sin terminos aceptados.
      final botonBloqueado = tester.widget<FilledButton>(
        find.byKey(const Key('boton_registrar')),
      );
      expect(botonBloqueado.onPressed, isNull);
      expect(
        find.textContaining('Activa la casilla de terminos'),
        findsOneWidget,
      );

      // Act 1: capturar datos con un codigo que NO cumple la RegExp.
      await tester.enterText(
        find.byKey(const Key('campo_codigo')),
        'codigo-malo',
      );
      await tester.enterText(
        find.byKey(const Key('campo_titulo')),
        'Fuga reportada en campo',
      );
      await tester.enterText(
        find.byKey(const Key('campo_detalle')),
        'Se detecto una fuga en el tanque principal de agua potable.',
      );

      // Assert 2: aun sin terminos el boton sigue bloqueado.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('boton_registrar')))
            .onPressed,
        isNull,
      );

      // Act 2: aceptar los terminos de seguridad.
      await asegurarVisible(tester, find.byKey(const Key('terminos_seguridad')));
      await tester.tap(find.byKey(const Key('terminos_seguridad')));
      await tester.pumpAndSettle();

      // Assert 3: el boton se habilita.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('boton_registrar')))
            .onPressed,
        isNotNull,
      );

      // Act 3: enviar con codigo invalido -> el Form reporta la RegExp.
      await asegurarVisible(tester, find.byKey(const Key('boton_registrar')));
      await tester.tap(find.byKey(const Key('boton_registrar')));
      await tester.pumpAndSettle();

      // Assert 4
      expect(find.textContaining('Formato requerido'), findsOneWidget);
      expect(escenario.repositorio.reportes, hasLength(3),
          reason: 'Nada debe persistir si la validacion falla');

      // Act 4: corregir el codigo y reenviar.
      await asegurarVisible(tester, find.byKey(const Key('campo_codigo')));
      await tester.enterText(
        find.byKey(const Key('campo_codigo')),
        'EC-2026-AL',
      );
      await asegurarVisible(tester, find.byKey(const Key('boton_registrar')));
      await tester.tap(find.byKey(const Key('boton_registrar')));
      await tester.pumpAndSettle();

      // Assert 5: persistido en la "base local" y notificado.
      expect(escenario.repositorio.reportes, hasLength(4));
      expect(find.textContaining('guardado en SQLite'), findsOneWidget);
      expect(escenario.formulario.aceptaTerminos, isFalse,
          reason: 'restablecer() vuelve a bloquear el envio');
    });

    testWidgets(
        'Arrange: reporte recien guardado | Act: volver al panel | '
        'Assert: el listado observable lo muestra', (tester) async {
      // Arrange
      final escenario = await preparar(tester);
      await navegarA(tester, 'Nuevo');

      await tester.enterText(
        find.byKey(const Key('campo_codigo')),
        'EC-2026-XX',
      );
      await tester.enterText(
        find.byKey(const Key('campo_titulo')),
        'Novedad detectada en ruta',
      );
      await tester.enterText(
        find.byKey(const Key('campo_detalle')),
        'El repartidor reporto una novedad en el punto de entrega.',
      );
      await asegurarVisible(tester, find.byKey(const Key('terminos_seguridad')));
      await tester.tap(find.byKey(const Key('terminos_seguridad')));
      await tester.pumpAndSettle();

      // Act
      await asegurarVisible(tester, find.byKey(const Key('boton_registrar')));
      await tester.tap(find.byKey(const Key('boton_registrar')));
      await tester.pumpAndSettle();

      // Assert: la app regresa al panel y el ListenableBuilder repinta.
      expect(escenario.reportes.categoriaActiva, isNull);
      expect(escenario.reportes.total, 4);
      expect(find.textContaining('Reportes en campo: 4'), findsOneWidget);

      // La SliverList construye las tarjetas bajo demanda: desplazar hasta
      // la recien guardada para comprobar que el dato llego hasta la vista.
      await tester.drag(
        find.byKey(const Key('panel_scroll')),
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novedad detectada en ruta'), findsOneWidget);
      expect(find.byKey(const Key('tarjeta_r_1')), findsOneWidget);
    });
  });

  group('Modulo 2.1 - Catalogo bidimensional con GridView.builder', () {
    testWidgets(
        'Arrange: catalogo local | Act: abrir la pestana Catalogo | '
        'Assert: grilla con SliverGridDelegateWithMaxCrossAxisExtent',
        (tester) async {
      // Arrange
      final escenario = await preparar(tester);

      // Act
      await navegarA(tester, 'Catalogo');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('grilla_zonas')), findsOneWidget);
      final grilla = tester.widget<GridView>(
        find.byKey(const Key('grilla_zonas')),
      );
      final delegado =
          grilla.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(delegado.maxCrossAxisExtent, 220);
      expect(delegado.childAspectRatio, moreOrLessEquals(0.78));
      expect(find.byKey(const Key('zona_z_1')), findsOneWidget);
      expect(find.text('Tunel Subterraneo 4'), findsOneWidget);

      // Act: filtrar por riesgo Critico con el chip del Wrap superior.
      await tester.tap(find.widgetWithText(FilterChip, 'Critica'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('zona_z_1')), findsNothing);
      expect(find.text('Tunel Subterraneo 4'), findsOneWidget);
      expect(find.text('Centro Logistico Norte'), findsNothing);
      expect(escenario.catalogo.riesgoActivo, 4);
    });
  });

  group('Modulo 3.3 - Boton "Sincronizar ahora" envia la cola offline', () {
    testWidgets(
        'Arrange: 3 reportes pendientes | '
        'Act: pulsar Sincronizar | '
        'Assert: el resumen baja a 0 pendientes y el estado lo informa',
        (tester) async {
      // Arrange: los tres reportes de la semilla nacen sin sincronizar.
      final escenario = await preparar(tester);
      expect(
        find.textContaining('Pendientes de sincronizar: 3'),
        findsOneWidget,
      );

      // Act
      await tester.tap(find.text('Sincronizar ahora'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.textContaining('Pendientes de sincronizar: 0'),
        findsOneWidget,
        reason: 'Tras sincronizar el contador del panel debe bajar a 0',
      );
      expect(escenario.repositorio.reportesEnviados, 3);
      expect(escenario.repositorio.reportes.every((r) => r.sincronizado),
          isTrue);
      expect(escenario.catalogo.estadoRed, contains('3 reportes enviados'));
    });

    testWidgets(
        'Arrange: cola pendiente con la red caida | '
        'Act: pulsar Sincronizar | '
        'Assert: los reportes siguen pendientes y el aviso lo dice',
        (tester) async {
      // Arrange
      final escenario = await preparar(tester);
      escenario.repositorio.redCaida = true;

      // Act
      await tester.tap(find.text('Sincronizar ahora'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.textContaining('Pendientes de sincronizar: 3'),
        findsOneWidget,
        reason: 'Sin confirmacion de la API nadie se marca como sincronizado',
      );
      expect(escenario.repositorio.reportesEnviados, 0);
      expect(escenario.catalogo.estadoRed, contains('Sin conexion'));
    });
  });
}
