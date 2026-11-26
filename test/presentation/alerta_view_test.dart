import 'package:ecotrack/presentation/controllers/alerta_controller.dart';
import 'package:ecotrack/presentation/controllers/catalogo_controller.dart';
import 'package:ecotrack/presentation/controllers/formulario_controller.dart';
import 'package:ecotrack/presentation/controllers/reporte_controller.dart';
import 'package:ecotrack/presentation/views/ecotrack_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/repositorio_falso.dart';

void main() {
  testWidgets(
      'Modulo 4 - Arrange: vista Alerta sin impactos | '
      'Act: pulsar simulacion manual | '
      'Assert: banner visual y tarjeta de emergencia', (tester) async {
    // Arrange
    final repositorio = RepositorioFalso();
    final alertas = AlertaController.sinServicio();
    final reportes = ReporteController(repositorio: repositorio);
    final catalogo = CatalogoController(repositorio: repositorio);

    await tester.pumpWidget(
      EcoTrackApp(
        reportes: reportes,
        catalogo: catalogo,
        formulario: FormularioController(),
        alertas: alertas,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alerta'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sin_alertas')), findsOneWidget);
    expect(find.byKey(const Key('boton_simular_alerta')), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('boton_simular_alerta')));
    await tester.pumpAndSettle();

    // Assert
    expect(alertas.alertaActiva, isTrue);
    expect(alertas.totalAlertas, 1);
    expect(find.byKey(const Key('banner_alerta_impacto')), findsOneWidget);
    expect(find.byKey(const Key('tarjeta_alerta_impacto')), findsOneWidget);
    expect(find.textContaining('Eje X'), findsWidgets);

    // Act 2: cerrar el aviso desde la X del banner flotante.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Assert 2
    expect(alertas.alertaActiva, isFalse);
    expect(find.byKey(const Key('banner_alerta_impacto')), findsNothing);
  });
}
