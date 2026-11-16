# MoviRehab
Proyecto de Diseño de Interfaces IES Alfonso X El Sabio

## Descripción del proyecto
El proyecto se basa en la creación de una aplicación sencilla orientada al seguimiento de estiramientos y flexibilidad articular.

## Distribución de tareas
<a href="https://trello.com/invite/b/6ae0b54ca227916c4d782d88/ATTI08e67fcf3581f4d8b2f6fd551370d7a4E19B281B/movirehab-ejercicios-de-movilidad">Trello</a>

---

## Funcionalidades (versión 2.0)

| Pantalla | Qué hace |
| --- | --- |
| Inicio | Título de la app, saludo al usuario activo, **estadísticas** (sesiones, repeticiones, movilidad media, racha), gráfico de la última semana y **calendario de actividad** con el detalle de cada día. Todas las opciones están en un **menú desplegable** (icono ☰). |
| Perfil y usuarios | **Varios usuarios**: crear, cambiar de usuario, renombrar y eliminar (siempre queda uno). *Ver ejercicios* abre el historial de ese usuario. |
| Plan de Ejercicios | Los 10 ejercicios preestablecidos **más los tuyos**. *Nuevo ejercicio*: nombre, articulación y recorrido en grados (10°–180°). |
| Detalle de ejercicio | Cambia el objetivo en grados (10°–180°) y lo guarda. Los ejercicios propios se pueden eliminar. |
| Sesión Guiada NUI | **Modo automático (móvil):** el acelerómetro mide el ángulo y cuenta las repeticiones sin pulsar nada. **Modo manual:** botón *Simular ángulo* (+15° y +1 repetición); es el único modo en Windows. Guardas mediciones de varios ejercicios y *Finalizar sesión* abre el resumen. |
| Resumen de Sesión | Fecha, nº de ejercicios y media de grados. Compartir copia el resumen al portapapeles. |
| Progreso y Estadísticas | Totales, racha, gráfico semanal, evolución de la media de grados y barras de progreso por ejercicio frente a su objetivo. |
| Historial de Mediciones | Mediciones del usuario activo (o del que elijas en Perfil), de la más reciente a la más antigua. |
| Ajustes y Permisos | **Modo oscuro**, **idioma (Español / English) con cambio inmediato**, estado del sensor de movimiento, permisos de cámara y micrófono (Android) y acceso a la privacidad. |
| Privacidad | Aviso mejorado en apartados desplegables: tratamiento local, datos guardados, usos, sensores y permisos, compartir, control de los datos y aviso de salud. |

Idiomas: **español e inglés**. Se usa el idioma del dispositivo hasta que eliges uno en Ajustes (queda guardado). Los nombres de los 10 ejercicios preestablecidos y de las articulaciones se traducen; los ejercicios que crees conservan el nombre que les pongas.

### Medición con el sensor del móvil

- Usa el **acelerómetro** (no necesita permisos). Al pulsar *Iniciar medición* la posición del móvil es **0°**; el ángulo es la inclinación respecto a esa posición (0–180°).
- Cuenta una repetición cuando el ángulo sube hasta cerca del objetivo y vuelve cerca del inicio (con histéresis y pausa mínima de 0,5 s para evitar dobles conteos). *Poner a 0°* recalibra.
- **Limitación:** el acelerómetro mide la inclinación respecto a la gravedad. Un giro alrededor del eje vertical (por ejemplo una rotación con el brazo pegado al cuerpo y el móvil plano) no cambia la inclinación y no se detecta. Para eso haría falta el giroscopio; en esos casos usa el modo manual.
- En **Windows** (sin sensor) la app indica que se usa el modo manual.

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
| Android | ✅ Soportada (`sqflite` nativo). |
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
  main.dart                 Arranque, tema, idioma y rutas
  routes.dart               Nombres de ruta
  theme/app_theme.dart      Tema «naturaleza» claro y oscuro
  controllers/              MoviRehabController, AjustesController (tema/idioma),
                            MedidorMovimiento (sensor + repeticiones)
  models/                   Modelos de datos, actividad diaria y estadísticas
  services/
    rehab_repository.dart   Contrato de acceso a datos
    database_helper.dart    Implementación SQLite (esquema v3)
    fuente_movimiento.dart  Acelerómetro (sensors_plus) o «no disponible»
    calculador_angulo.dart  Muestras del acelerómetro -> grados
    contador_repeticiones.dart  Grados -> repeticiones
  views/                    Pantallas
  widgets/                  Fondo, menú lateral, calendario, gráficos y tarjetas
  utils/                    Formato de decimales y nombres localizados
  l10n/                     app_es.arb, app_en.arb (+ código generado)
packages/movirehab_components/   AngleGauge y SessionSummaryCard
test/                       Tests de la app (con repositorio en memoria)
```

## Base de datos

SQLite local (`movirehab.db`, en la carpeta *Documentos* del usuario en Windows y en el almacenamiento privado de la app en Android). Tablas: `usuario`, `ejercicio` (con la marca `personalizado`), `sesion`, `medicion` y `ajuste` (tema, idioma y usuario activo). Esquema **versión 3**: una base de datos v2 se actualiza **conservando todos los datos**. Se crea y se rellena sola con datos de demostración en el primer arranque.

Si quieres empezar de cero, borra `movirehab.db` (Windows) o los datos de la app (Android).

## Localización

Los textos viven en `lib/l10n/app_es.arb` (plantilla) y `app_en.arb`. Tras editarlos ejecuta `flutter pub get` (o `flutter gen-l10n`) para regenerar `lib/l10n/app_localizations*.dart`, que no se guarda en git.

## Qué se corrigió respecto a la versión anterior

Consulta [`docs/INFORME_MEJORAS.md`](docs/INFORME_MEJORAS.md).
