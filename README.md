# MoviRehab
Proyecto de Diseño de Interfaces IES Alfonso X El Sabio

## Descripción del proyecto
El proyecto se basa en la creación de una aplicación sencilla orientada al seguimiento de estiramientos y flexibilidad articular.

## Distribución de tareas
<a href="https://trello.com/invite/b/6ae0b54ca227916c4d782d88/ATTI08e67fcf3581f4d8b2f6fd551370d7a4E19B281B/movirehab-ejercicios-de-movilidad">Trello</a>

---

## Funcionalidades

| Pantalla | Qué hace |
| --- | --- |
| Inicio | Menú principal, aviso de privacidad y ajustes. |
| Perfil de Usuario | Muestra el usuario guardado en SQLite. |
| Plan de Ejercicios | Lista los 10 ejercicios del plan con su objetivo en grados. |
| Detalle de ejercicio | Cambia el objetivo (15°–180°) y lo guarda en SQLite. |
| Sesión Guiada NUI | Eliges un ejercicio, simulas el ángulo (+15° y +1 repetición por pulsación), **guardas la medición** y repites con otros ejercicios. *Finalizar sesión* abre el resumen. |
| Resumen de Sesión | Fecha, nº de ejercicios y media de grados de la sesión (o de la última sesión si se abre desde Inicio). El botón compartir copia el resumen al portapapeles. |
| Progreso y Medias | Media de grados y repeticiones totales por ejercicio. |
| Historial de Mediciones | Todas las mediciones, de la más reciente a la más antigua. |
| Ajustes y Permisos | Estado real de los permisos de cámara y micrófono (Android). En Windows indica «No aplica». |

> **Nota:** el ángulo de la Sesión Guiada es una **simulación**. Todavía no hay detección de pose con cámara ni control por voz; por eso se eliminaron del proyecto las dependencias que nunca se llegaron a usar (`speech_to_text`, `flutter_tts`, `google_mlkit_pose_detection`, `sensors_plus`, `go_router`).

Idiomas: español (por defecto) e inglés, según el idioma del dispositivo. Los nombres de los ejercicios y articulaciones son datos de la base de datos y se muestran siempre en español.

## Requisitos

- Flutter **3.47.x** (Dart 3.13+). Comprueba con `flutter --version` y `flutter doctor`.
- Visual Studio Code con las extensiones **Dart** y **Flutter** (VS Code te las sugiere al abrir la carpeta).
- **Windows:** Visual Studio 2022 con la carga de trabajo «Desarrollo para el escritorio con C++» y el *Modo desarrollador* de Windows activado (necesario para los enlaces simbólicos de los plugins).
- **Android:** Android Studio / SDK de Android y un emulador o un móvil con depuración USB.

## Cómo ejecutarlo desde Visual Studio Code

1. Descomprime el ZIP y abre la carpeta `MoviRehab` (*Archivo → Abrir carpeta*).
2. Abre una terminal (`Ctrl+Ñ`) y ejecuta `flutter pub get`. Esto también genera la localización en `lib/l10n/`.
3. Elige el dispositivo en la barra inferior (Windows, o tu emulador/móvil Android).
4. Pulsa **F5** (o *Ejecutar → Iniciar depuración*). Hay configuraciones listas para Windows y Android en `.vscode/launch.json`.

Por terminal: `flutter run -d windows` o `flutter run -d android`.

La primera compilación de Android descarga Gradle (9.3.1) y puede tardar varios minutos.

### Plataformas

| Plataforma | Estado |
| --- | --- |
| Windows | ✅ Soportada (SQLite con `sqflite_common_ffi`). |
| Android | ❌ Soportada (`sqflite` nativo). |
| Web | ❌ No soportada (SQLite local y permisos no existen en navegador): la app muestra un aviso. |
| iOS / macOS / Linux | No incluidas en el proyecto. Se añadirían con `flutter create --platforms=ios .` (etc.). |

## Tests y análisis

```bash
flutter analyze
flutter test                                  # tests de la app (controlador, modelos y pantallas)
cd packages/movirehab_components && flutter test   # tests de los componentes
```

## Estructura

```
lib/
  main.dart                 Arranque, tema, idiomas y rutas
  routes.dart               Nombres de ruta
  controllers/              MoviRehabController (Provider + ChangeNotifier)
  models/                   Modelos de datos y de consultas
  services/
    rehab_repository.dart   Contrato de acceso a datos
    database_helper.dart    Implementación SQLite
  views/                    Pantallas
  widgets/                  Widgets compartidos (estados vacío/error)
  utils/formato.dart        Formato de decimales según el idioma
  l10n/                     app_es.arb, app_en.arb (+ código generado)
packages/movirehab_components/   AngleGauge y SessionSummaryCard
test/                       Tests de la app (con repositorio en memoria)
```

## Base de datos

SQLite local (`movirehab.db`, en la carpeta *Documentos* del usuario en Windows y en el almacenamiento privado de la app en Android). Tablas: `usuario`, `ejercicio`, `sesion`, `medicion` (versión 2 del esquema). Se crea y se rellena sola con datos de demostración en el primer arranque.

Si quieres empezar de cero, borra `movirehab.db` (Windows) o los datos de la app (Android).

## Localización

Los textos viven en `lib/l10n/app_es.arb` (plantilla) y `app_en.arb`. Tras editarlos ejecuta `flutter pub get` (o `flutter gen-l10n`) para regenerar `lib/l10n/app_localizations*.dart`, que no se guarda en git.

## Qué se corrigió respecto a la versión anterior

Consulta [`docs/INFORME_MEJORAS.md`](docs/INFORME_MEJORAS.md).
