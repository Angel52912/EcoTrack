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
  FuenteApiEcoTrack({required http.Client cliente, Uri? base})
      : _cliente = cliente,
        _base = base ?? AppConfig.apiZonas;

  final http.Client _cliente;
  final Uri _base;

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
}
