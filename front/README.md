# EcoTrack & RutaSegura - Front

Interfaz (solo front) de la app EcoTrack & RutaSegura, hecha en Flutter con
Material 3. Los datos son de demostración y viven en memoria
(`RepositorioMemoria`), así que la interfaz funciona sin backend.

> Práctica Final de Laboratorio - Universidad Tecnológica Metropolitana (UTM)

## Pantallas

| Pestaña | Qué hace | Widgets clave |
|---|---|---|
| **Panel** | Indicadores (reportes, críticos, pendientes, zonas en alerta), filtro por categoría, botón *Sincronizar* y lista de reportes con estado *Sincronizado* / *Pendiente de sincronizar* | `CustomScrollView`, `SliverAppBar` colapsable, `Wrap` + `FilterChip`, `SliverList` |
| **Catálogo** | Grilla de zonas con filtro por riesgo (Baja, Media, Alta, Crítica) y detalle al tocar | `GridView.builder` + `SliverGridDelegateWithMaxCrossAxisExtent`, `ChoiceChip`, `showModalBottomSheet` |
| **Nuevo** | Formulario de reporte: código `EC-2026-AL`, título, detalle, categoría, prioridad 1-5 y aceptación de términos | `Form` + `GlobalKey<FormState>`, validadores RegExp, botón con `onPressed: null` hasta aceptar |

La navegación es responsiva: `NavigationBar` en teléfono y `NavigationRail`
en pantallas de 840 px o más.

## Arquitectura

```
lib/
├── domain/
│   ├── entities/          Reporte, Zona (inmutables, getters, asserts)
│   ├── validadores/       ReglasReporte (RegExp)
│   └── repositories/      RepositorioReportes (interfaz)
├── data/
│   └── repositorio_memoria.dart   datos de demostración
└── presentation/
    ├── controllers/       ChangeNotifier + notifyListeners()
    └── views/             vistas pasivas con ListenableBuilder
```

No hay lógica de negocio dentro de los métodos `build`. Para conectar el
backend real basta con implementar `RepositorioReportes` y reemplazar
`RepositorioMemoria` en `lib/main.dart`.

## Ejecutar

```bash
flutter pub get
flutter run -d edge        # en el navegador (o -d chrome)
flutter test               # pruebas con patrón Arrange-Act-Assert
```

Para Android, genera primero la carpeta de la plataforma:

```bash
flutter create --platforms=android .
flutter run
```
