import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../configuracion.dart';
import '../models/zona_model.dart';

/// Modulo 3 - Capa `data`, fuente remota (`http`).
///
/// Descarga informacion desde una API REST publica, inyecta la cabecera de
/// seguridad `Authorization: Bearer <token>`, decodifica el JSON y
/// **propaga cualquier excepcion de red mediante `rethrow`** para que la capa
/// de presentacion decida que hacer (estrategia Offline-First).
class FuenteApiEcoTrack {
  FuenteApiEcoTrack({
    required http.Client cliente,
    Uri? base,
    Uri? baseReportes,
  })  : _cliente = cliente,
        _base = base ?? AppConfig.apiZonas,
        _baseReportes = baseReportes ?? AppConfig.apiReportes;

  final http.Client _cliente;
  final Uri _base;

  /// Endpoint de subida de reportes (cola offline -> nube).
  final Uri _baseReportes;

  /// Descarga el catalogo de zonas desde la nube.
  Future<List<ZonaModel>> descargarZonas({required String token}) async {
    try {
      final respuesta = await _cliente.get(
        _base,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (respuesta.statusCode != 200) {
        throw http.ClientException(
          'La API respondio HTTP ${respuesta.statusCode}',
          _base,
        );
      }

      final cuerpo = jsonDecode(respuesta.body) as List<dynamic>;
      return cuerpo
          .map((elemento) =>
              ZonaModel.desdeApi(elemento as Map<String, dynamic>))
          .toList();
    } catch (error) {
      // Excepcion de red, JSON invalido o status != 200: se propaga tal cual.
      rethrow;
    }
  }

  /// Sube un reporte de la cola offline a la nube (Modulo 3.3).
  ///
  /// Mismo contrato que [descargarZonas]: cabecera `Authorization` y
  /// **cualquier fallo se propaga con `rethrow`** para que el llamador decida
  /// si reintenta (Workmanager) o si conserva el registro como pendiente.
  Future<void> subirReporte({
    required Map<String, Object?> reporte,
    required String token,
  }) async {
    try {
      final respuesta = await _cliente.post(
        _baseReportes,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_paraNube(reporte)),
      );

      final correcto = respuesta.statusCode >= 200 && respuesta.statusCode < 300;
      if (!correcto) {
        throw http.ClientException(
          'La API rechazo el reporte con HTTP ${respuesta.statusCode}',
          _baseReportes,
        );
      }
    } catch (error) {
      // Excepcion de red o status fuera de 2xx: se propaga tal cual.
      rethrow;
    }
  }

  /// Limpia el mapa antes de viajar a la nube: `sincronizado` es un estado
  /// local y los campos extraños al contrato no viajan.
  Map<String, Object?> _paraNube(Map<String, Object?> reporte) => {
        'id': reporte['id'],
        'codigo': reporte['codigo'],
        'titulo': reporte['titulo'],
        'detalle': reporte['detalle'],
        'categoria': reporte['categoria'],
        'prioridad': reporte['prioridad'],
        'registrado_en': reporte['registrado_en'],
      };
}
