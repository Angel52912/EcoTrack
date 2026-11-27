# EcoTrack & RutaSegura Mobile

Aplicacion movil multiplataforma (Flutter) para supervisores y repartidores de
una empresa de distribucion ecologica. Opera bajo la estrategia **Offline-First**:
registra novedades de campo sin conexion y las sincroniza con la nube en cuanto
hay red.

> Prctica Final de Laboratorio - Unidades II, III y IV
> Universidad Tecnologica Metropolitana (UTM)
> Repositorio: https://github.com/Angel52912/EcoTrack.git

---

## Arquitectura Limpia por Capas

```
lib/
├── domain/                    # Reglas de negocio (sin Flutter ni SQL)
│   ├── entities/              #   Reporte, Zona: inmutables, getters,
│   │                          #   listas de inicializacion y asserts
│   ├── validadores/           #   ReglasReporte (validaciones con RegExp)
│   └── repositories/          #   Puertos (interfaces) del dominio
├── data/                      # Implementacion de la infraestructura
│   ├── models/                #   toMap / fromMap (serializacion SQLite)
│   ├── local/                 #   AppDatabase (.db) + patrones DAO
│   ├── remote/                #   FuenteApiEcoTrack (http + Bearer JWT)
│   ├── repositories/          #   RepositorioReportesImpl (Offline-First)
│   ├── sensores/              #   FuenteAcelerometro (sensors_plus -> dominio)
│   ├── services/              #   ServicioAlertasLocal (audioplayers + notificaciones)
│   ├── sincronizacion/        #   SincronizadorReportes (cola offline -> API)
│   └── workmanager/           #   Tarea periodica @pragma('vm:entry-point')
└── presentation/
    ├── controllers/           #   ChangeNotifier con notifyListeners()
    └── views/                 #   Vistas pasivas Material 3
```

**Regla de Oro respetada:** no existe logica de negocio, SQL ni peticiones HTTP
dentro de los metodos `build`.

---

## Modulos implementados

| Modulo | Contenido | Ubicacion |
|---|---|---|
| **1. Arquitectura y GitFlow** | Tres paquetes aislados, `.gitignore` estricto, ramas `main` / `develop` / `feature/*` con Pull Requests | todo el repo |
| **2. UI y estado desacoplado** | `CustomScrollView` + `SliverAppBar` colapsable, filtros `Wrap`, `GridView.builder` con `SliverGridDelegateWithMaxCrossAxisExtent`, `Form` + `GlobalKey<FormState>` con RegExp, boton bloqueado (`onPressed: null`) hasta aceptar terminos, `ChangeNotifier` + `ListenableBuilder` | `lib/presentation/` |
| **3. Persistencia y API** | SQLite `.db` con patron DAO, columnas explicitas y `whereArgs` (anti inyeccion SQL); API REST con cabecera `Authorization: Bearer <token>`, decodificacion JSON y `rethrow` | `lib/data/` |
| **4. Sensores, multimedia y notificaciones** | Acelerometro (`sensors_plus`) escuchado en `initState`, umbral 15 m/s2 en X/Y/Z, audio local `assets/audio/` con cooldown y simulacion manual, notificacion `Importance.max`, Workmanager con `NetworkType.connected` que **sincroniza la cola offline real** (DAO pendientes -> API -> marcar; la ruta del `.db` viaja en `inputData` para que el isolate FFI abra el mismo archivo que la app) y liberacion total en `dispose()` | `lib/data/sensores/`, `lib/data/services/`, `lib/data/workmanager/`, `lib/data/sincronizacion/`, `lib/presentation/controllers/alerta_controller.dart` |
| **3.3 Boton "Sincronizar ahora"** | El boton del panel sube la cola de reportes pendientes **y** descarga el catalogo (`RepositorioReportes.sincronizarReportesPendientes`), luego refresca el resumen para que el contador baje a 0 | `lib/presentation/controllers/catalogo_controller.dart`, `lib/presentation/views/panel_view.dart` |
| **5. Calidad y telemetria** | 70 pruebas (unitarias + widgets) con patron Arrange-Act-Assert, `FlutterError.onError` y `PlatformDispatcher.instance.onError` | `test/`, `lib/telemetria.dart`, `lib/main.dart` |

---

## Puesta en marcha

```bash
flutter pub get
flutter analyze
flutter test                 # 70 pruebas en verde
flutter run                  # en dispositivo/emulador Android
```

Compilacion de produccion (solo cuando el docente lo indique):

```bash
flutter build apk --release  # build/app/outputs/flutter-apk/app-release.apk
```

---

## Estrategia Offline-First

1. Toda captura se escribe primero en `ecotrack.db` (patron DAO).
2. `CatalogoController.sincronizar()` intenta descargar el catalogo con JWT.
3. Si la red falla, la excepcion se captura en el controlador: **los datos
   locales quedan intactos** y la interfaz solo informa "Sin conexion".
4. El listado de reportes distingue `Sincronizado` / `Pendiente de sincronizar`.
