import '../domain/entities/reporte.dart';
import '../domain/entities/zona.dart';
import '../domain/repositories/repositorio_reportes.dart';

/// Capa `data` - Implementacion en memoria con datos de demostracion.
///
/// Solo existe para que el front funcione por si mismo. Simula una pequena
/// latencia para que la UI muestre sus estados de carga.
class RepositorioMemoria implements RepositorioReportes {
  RepositorioMemoria({
    List<Reporte>? reportes,
    List<Zona>? zonas,
    this.latencia = const Duration(milliseconds: 350),
  }) : _reportes = [...(reportes ?? _reportesDemo())],
       _zonas = [...(zonas ?? _zonasDemo)];

  final List<Reporte> _reportes;
  final List<Zona> _zonas;
  final Duration latencia;

  Future<void> _esperar() =>
      latencia == Duration.zero ? Future.value() : Future.delayed(latencia);

  @override
  Future<List<Reporte>> obtenerReportes() async {
    await _esperar();
    return List.unmodifiable(_reportes);
  }

  @override
  Future<void> guardarReporte(Reporte reporte) async {
    await _esperar();
    _reportes
      ..removeWhere((r) => r.id == reporte.id)
      ..insert(0, reporte);
  }

  @override
  Future<void> eliminarReporte(String id) async {
    await _esperar();
    _reportes.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<Reporte>> sincronizarPendientes() async {
    await _esperar();
    for (var i = 0; i < _reportes.length; i++) {
      if (_reportes[i].pendienteDeSincronizar) {
        _reportes[i] = _reportes[i].copiarCon(sincronizado: true);
      }
    }
    return List.unmodifiable(_reportes);
  }

  @override
  Future<List<Zona>> obtenerZonas() async {
    await _esperar();
    return List.unmodifiable(_zonas);
  }

  // ---------------------------------------------------------------------------
  // Datos de demostracion
  // ---------------------------------------------------------------------------
  static List<Reporte> _reportesDemo() {
    final ahora = DateTime.now();
    return [
      Reporte(
        id: 'r_1',
        codigo: 'EC-2026-AL',
        titulo: 'Bache profundo en periferico',
        detalle:
            'Bache de 40 cm en el carril derecho, km 12. Riesgo para la suspension.',
        categoria: 'Ruta',
        prioridad: 4,
        registradoEn: ahora.subtract(const Duration(hours: 2)),
      ),
      Reporte(
        id: 'r_2',
        codigo: 'EC-2026-CG',
        titulo: 'Carga mal estibada',
        detalle:
            'Tres cajas de producto organico llegaron golpeadas al centro de acopio.',
        categoria: 'Carga',
        prioridad: 3,
        registradoEn: ahora.subtract(const Duration(hours: 5)),
        sincronizado: true,
      ),
      Reporte(
        id: 'r_3',
        codigo: 'EC-2026-SG',
        titulo: 'Zona sin iluminacion',
        detalle:
            'Calle 60 sin alumbrado publico; se recomienda entregar antes de las 19:00.',
        categoria: 'Seguridad',
        prioridad: 5,
        registradoEn: ahora.subtract(const Duration(days: 1)),
      ),
      Reporte(
        id: 'r_4',
        codigo: 'EC-2026-AM',
        titulo: 'Contenedor de reciclaje lleno',
        detalle:
            'El contenedor del parque ecologico esta al 100%, solicitar recoleccion.',
        categoria: 'Ambiental',
        prioridad: 2,
        registradoEn: ahora.subtract(const Duration(days: 2)),
        sincronizado: true,
      ),
    ];
  }

  static final List<Zona> _zonasDemo = [
    Zona(
      id: 'z_1',
      nombre: 'Centro Historico',
      ruta: 'RUTA-101',
      riesgo: 2,
      entregasPendientes: 6,
      tipoIcono: Zona.tipoRuta,
      lugar: TipoLugar.centro,
    ),
    Zona(
      id: 'z_2',
      nombre: 'Zona Industrial Norte',
      ruta: 'RUTA-102',
      riesgo: 3,
      entregasPendientes: 12,
      tipoIcono: Zona.tipoCamion,
      lugar: TipoLugar.industrial,
    ),
    Zona(
      id: 'z_3',
      nombre: 'Parque Ecologico',
      ruta: 'RUTA-103',
      riesgo: 1,
      entregasPendientes: 2,
      tipoIcono: Zona.tipoPaquete,
      lugar: TipoLugar.parque,
    ),
    Zona(
      id: 'z_4',
      nombre: 'Periferico Oriente',
      ruta: 'RUTA-204',
      riesgo: 4,
      entregasPendientes: 9,
      tipoIcono: Zona.tipoAlerta,
      lugar: TipoLugar.vialidad,
    ),
    Zona(
      id: 'z_5',
      nombre: 'Central de Abastos',
      ruta: 'RUTA-205',
      riesgo: 3,
      entregasPendientes: 14,
      tipoIcono: Zona.tipoCamion,
      lugar: TipoLugar.mercado,
    ),
    Zona(
      id: 'z_6',
      nombre: 'Colonia Mexico',
      ruta: 'RUTA-206',
      riesgo: 1,
      entregasPendientes: 4,
      tipoIcono: Zona.tipoPaquete,
      lugar: TipoLugar.residencial,
    ),
    Zona(
      id: 'z_7',
      nombre: 'Puerto Progreso',
      ruta: 'RUTA-307',
      riesgo: 2,
      entregasPendientes: 7,
      tipoIcono: Zona.tipoRuta,
      lugar: TipoLugar.puerto,
    ),
    Zona(
      id: 'z_8',
      nombre: 'Caucel Poniente',
      ruta: 'RUTA-308',
      riesgo: 4,
      entregasPendientes: 11,
      tipoIcono: Zona.tipoAlerta,
      lugar: TipoLugar.vialidad,
    ),
    Zona(
      id: 'z_9',
      nombre: 'Ciudad Caucel',
      ruta: 'RUTA-309',
      riesgo: 2,
      entregasPendientes: 0,
      tipoIcono: Zona.tipoPaquete,
      lugar: TipoLugar.residencial,
    ),
    Zona(
      id: 'z_10',
      nombre: 'Zona Universitaria',
      ruta: 'RUTA-410',
      riesgo: 1,
      entregasPendientes: 3,
      tipoIcono: Zona.tipoRuta,
      lugar: TipoLugar.universidad,
    ),
    Zona(
      id: 'z_11',
      nombre: 'Aeropuerto',
      ruta: 'RUTA-411',
      riesgo: 3,
      entregasPendientes: 8,
      tipoIcono: Zona.tipoCamion,
      lugar: TipoLugar.aeropuerto,
    ),
    Zona(
      id: 'z_12',
      nombre: 'Fracc. Las Americas',
      ruta: 'RUTA-412',
      riesgo: 2,
      entregasPendientes: 5,
      tipoIcono: Zona.tipoPaquete,
      lugar: TipoLugar.residencial,
    ),
  ];
}
