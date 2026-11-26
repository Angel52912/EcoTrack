/// Configuracion central de la aplicacion (endpoints y credenciales demo).
///
/// En un proyecto real el token llegaria desde un servicio de autenticacion;
/// aqui se conserva como constante de desarrollo y **nunca** se hardcodea
/// dentro de un widget (Regla de Oro).
library;

class AppConfig {
  /// Endpoint publico utilizado para demostrar el consumo de API REST.
  static final Uri apiZonas = Uri.parse(
    'https://jsonplaceholder.typicode.com/albums/1/photos',
  );

  /// Endpoint al que se **suben** los reportes de la cola offline
  /// (Modulo 3.3 + Módulo 4.3, tarea periodica de sincronizacion).
  static final Uri apiReportes = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts',
  );

  /// Token JWT (ficticio, firmado solo para la practica) que se inyecta en la
  /// cabecera `Authorization: Bearer <token>` de cada peticion.
  static const String tokenJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiJzdXBlcnZpc29yLXV0bSIsInJvbCI6ImZsZWV0LXN1cGVydmlzb3IiLCJpYXQiOjE3NjcyMDAwMH0.'
      'firma-demo-ecotrack-rutasegura';

  static const String nombreApp = 'EcoTrack & RutaSegura';
}
