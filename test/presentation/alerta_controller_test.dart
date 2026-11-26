import 'dart:async';

import 'package:ecotrack/domain/entities/alerta_impacto.dart';
import 'package:ecotrack/domain/entities/lectura_acelerometro.dart';
import 'package:ecotrack/domain/repositories/servicio_alertas.dart';
import 'package:ecotrack/presentation/controllers/alerta_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doble de prueba: registra cada efecto sin tocar plugins nativos.
class ServicioAlertasFalso implements ServicioAlertas {
  int inicializaciones = 0;
  int reproducciones = 0;
  int emergencias = 0;
  int envios = 0;
  int liberaciones = 0;
  AlertaImpacto? ultimaAlerta;
  String? ultimoCodigo;

  @override
  Future<void> inicializar() async => inicializaciones++;

  @override
  Future<void> reproducirAlerta() async => reproducciones++;

  @override
  Future<void> notificarEmergencia(AlertaImpacto alerta) async {
    emergencias++;
    ultimaAlerta = alerta;
  }

  @override
  Future<void> notificarEnvioConfirmado(String codigo) async {
    envios++;
    ultimoCodigo = codigo;
  }

  @override
  void liberar() => liberaciones++;
}

void main() {
  late StreamController<LecturaAcelerometro> sensor;
  late ServicioAlertasFalso servicio;
  late AlertaController controlador;

  setUp(() {
    sensor = StreamController<LecturaAcelerometro>.broadcast();
    servicio = ServicioAlertasFalso();
    controlador = AlertaController(
      servicio: servicio,
      acelerometro: sensor.stream,
      cooldown: const Duration(seconds: 30),
      duracionAlerta: const Duration(seconds: 30),
    );
  });

  tearDown(() {
    controlador.dispose();
    sensor.close();
  });

  test(
      'Arrange: sensor en escucha | Act: lectura con eje Z > 15 | '
      'Assert: alerta visual, audio y notificacion', () async {
    // Act
    controlador.iniciarMonitoreo();
    sensor.add(const LecturaAcelerometro(x: 1, y: 2, z: 20.5));
    await pumpEventQueue();

    // Assert
    expect(controlador.monitoreando, isTrue);
    expect(controlador.alertaActiva, isTrue);
    expect(controlador.alerta!.eje, 'Z');
    expect(controlador.totalAlertas, 1);
    expect(servicio.reproducciones, 1);
    expect(servicio.emergencias, 1);
  });

  test(
      'Arrange: cooldown de 30s | Act: dos impactos seguidos | '
      'Assert: solo se dispara el primero', () async {
    // Act
    await controlador.simularAlerta();
    await controlador.simularAlerta();

    // Assert
    expect(controlador.totalAlertas, 1);
    expect(servicio.reproducciones, 1);
    expect(servicio.emergencias, 1);
    expect(controlador.enEnfriamiento, isTrue);
  });

  test(
      'Arrange: envio confirmado | Act: confirmarEnvio(codigo) | '
      'Assert: notificacion prioritaria con el codigo', () async {
    await controlador.confirmarEnvio('EC-2026-AL');

    expect(servicio.envios, 1);
    expect(servicio.ultimoCodigo, 'EC-2026-AL');
  });

  test(
      'Arrange: suscripcion activa | Act: dispose() | '
      'Assert: se cancela el Stream y se libera el AudioPlayer', () async {
    // Arrange
    controlador.iniciarMonitoreo();
    expect(controlador.monitoreando, isTrue);

    // Act: el tearDown tambien llama a dispose; aqui se fuerza una segunda
    // lectura despues de liberar para comprobar que no hay suscripcion viva.
    controlador.dispose();
    sensor.add(const LecturaAcelerometro(x: 40, y: 0, z: 0));
    await pumpEventQueue();

    // Assert
    expect(servicio.liberaciones, 1);
    expect(controlador.totalAlertas, 0);
    expect(controlador.monitoreando, isFalse);
  });
}
