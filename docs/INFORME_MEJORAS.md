# Informe de análisis y mejoras de MoviRehab

> Este documento tiene dos partes: la **versión 2.0** (nuevas mejoras pedidas sobre la app base) y, más abajo, el análisis de errores de la versión 1.

Este documento resume los problemas que se encontraron en la versión original del proyecto y qué se hizo con cada uno. Se mantuvo la funcionalidad original; los cambios de comportamiento son los que se acordaron expresamente (ver «Decisiones acordadas»).

---

# Versión 2.0 — mejoras sobre la app base

Se partió de la app entregada sin cambiar sus funcionalidades base (plan, detalle, sesión guiada, resumen, progreso, historial, ajustes, perfil, privacidad, ES/EN).

| # | Mejora pedida | Qué se hizo |
| --- | --- | --- |
| 1 | Interfaz más visual, colores de naturaleza | Tema propio con verdes de bosque/musgo, tierra cálida y fondos crema (claro) o verde muy oscuro (oscuro); tarjetas redondeadas, fondo con degradado y contenido centrado (ancho máx. 760 px, cómodo en Windows y móvil). Contrastes de texto calculados (≥ 4,5:1). |
| 2 | Modo oscuro en Ajustes | Interruptor en Ajustes; se aplica al instante y se guarda (tabla `ajuste`). Hasta que se elige, se sigue el tema del sistema. |
| 3 | Contar repeticiones con el sensor | Acelerómetro (`sensors_plus`): calibración de 0°, filtrado, rechazo de muestras anómalas, histéresis y pausa mínima. Vibración al completar una repetición. Modo manual como alternativa y para Windows. |
| 4 | Estadísticas mejoradas | Tarjetas de totales, racha actual y mejor racha, gráfico semanal, línea de evolución y barras por ejercicio frente al objetivo. Gráficos propios (sin paquetes). |
| 5 | Varios usuarios | Crear, seleccionar, renombrar y eliminar usuarios; cada usuario tiene sus sesiones, estadísticas e historial; *Ver ejercicios* en el perfil. El usuario activo se recuerda. |
| 6 | Crear más ejercicios | Pantalla *Nuevo ejercicio* (nombre, articulación, recorrido en grados). Se pueden borrar los propios; los 10 originales no. |
| 7 | Menú desplegable e inicio con estadísticas y calendario | Menú lateral (☰). Inicio: título, saludo, estadísticas, gráfico semanal y calendario con detalle por día. |
| 8 | Privacidad | Texto nuevo en 7 apartados desplegables; describe sensores, almacenamiento local, copias de seguridad de Android y salud. |
| 9 | Idioma en Ajustes | Selector Español / English con efecto inmediato (sin reiniciar). |

**Base de datos v3:** columna `ejercicio.personalizado` y tabla `ajuste`. La migración v2→v3 conserva los datos (comprobada en SQLite real).

**Ampliación de tests:** medidor de movimiento, calculador de ángulo, contador de repeticiones, ajustes, usuarios, ejercicios propios, sesión con sensor simulado, calendario/gráficos, privacidad, paridad de los `.arb` y temas.

**Privacidad y datos personales:** nada sale del dispositivo; la app no usa Internet.

## Cómo se comprobó la versión 2.0 (y qué no)

Igual que en la versión 1, **no hay SDK de Flutter en el entorno de trabajo, así que no se compiló ni se ejecutó la app ni los tests**. Se hizo: sintaxis y formato con el Dart SDK; el SQL (esquema, consultas por usuario, cascadas, migración v2→v3) contra SQLite real; paridad y placeholders de los `.arb`; comprobación cruzada de textos, imports y paquetes; APIs de Flutter y `sensors_plus` contrastadas con su código fuente; contrastes de color calculados.

**Qué no se pudo probar:** el comportamiento real del acelerómetro en un móvil (los umbrales de repetición pueden necesitar ajuste fino), el aspecto exacto de las pantallas y la ejecución de los tests.

**Primera vez:** `flutter pub get`, `flutter analyze`, `flutter test`. Si hay avisos o errores, envíalos y se corrigen.

---

# Versión 1 — análisis de errores

## Decisiones acordadas

| Tema | Decisión |
| --- | --- |
| Plataformas | Windows + Android. Web muestra un aviso de «no soportado». |
| Dependencias y localización | Se quitaron las dependencias sin uso y se activó el español/inglés (idioma del dispositivo). |
| Pantallas simuladas | Se conectaron de verdad: la Sesión Guiada guarda en SQLite, Resumen y Perfil leen la base de datos y Ajustes consulta permisos reales. |
| Sesión guiada | Varios ejercicios por sesión; cada pulsación de *Simular ángulo* suma 15° y 1 repetición. |
| Compartir resumen | Copia el texto al portapapeles. |
| Correcciones | Todas. |

## Errores corregidos

| # | Problema original | Corrección |
| --- | --- | --- |
| 1 | Historial de Mediciones salía vacío: nunca cargaba datos. | La pantalla carga sus datos al abrirse (`cargarHistorial`), con estados de carga, vacío y error. |
| 2 | El deslizador del detalle arrancaba siempre en 90°, y guardar sin tocarlo sobrescribía el objetivo. | Arranca en el objetivo real del ejercicio; pasa por constructor tipado en lugar de `ModalRoute`. Pasos de 1°. |
| 3 | `SessionSummaryCard` no pintaba su `title`. | Se muestra. |
| 4 | `AngleGauge.onTargetReached` no se disparaba si el widget nacía ya en la meta. | Se evalúa también en `initState`; se llama tras el frame (seguro para SnackBar) y se rearma si el ángulo baja. |
| 5 | 3 tests del paquete de componentes fallaban (título, meta inicial, `onTap` nunca pasado). | Corregidos y ampliados (13 tests). |
| 6 | `onUpgrade` volvía a crear las tablas sin borrar: «table usuario already exists» en una BD v1. | Se borran en orden hijo→padre y se recrean (reproducido y verificado en SQLite). |
| 7 | En Web: `Platform`, `sqflite` y `path_provider` no existen; Progreso quedaba con el spinner infinito. | Aviso de plataforma no soportada; todas las operaciones del controlador capturan errores. |
| 8 | `android/`, `ios/` y `linux/` solo tenían archivos autogenerados. | `android/` completo, generado desde las plantillas oficiales de Flutter 3.47.5 (Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0) con permisos de cámara y micrófono. Se quitaron `ios/` y `linux/`. |
| 9 | Localización sin conectar (sin `l10n.yaml`, `.arb` en la carpeta equivocada, sin delegates). | `l10n.yaml`, `.arb` en `lib/l10n/`, delegates y `supportedLocales`; todos los textos salen de los `.arb`. |
| 10 | 6 dependencias sin uso. | Eliminadas `speech_to_text`, `flutter_tts`, `google_mlkit_pose_detection`, `sensors_plus` y `go_router`. `permission_handler` se conserva porque ahora Ajustes lo usa. |
| 11 | Resumen inalcanzable y con datos fijos; compartir vacío. | Accesible desde Inicio (última sesión) y al finalizar una sesión; datos reales; compartir copia el texto. |
| 12 | Sesión Guiada no guardaba nada; Progreso e Historial solo podían mostrar 1 medición demo. | Elegir ejercicio (el medidor usa su objetivo), guardar mediciones y finalizar. La sesión se crea al guardar la primera medición. |
| 13 | Ajustes mostraba ✓ fijos. | Estado real de cámara y micrófono en Android, con botones Solicitar / Abrir ajustes. En Windows: «No aplica». |
| 14 | Perfil mostraba «Paciente Demo / ID 1» inventado. | Lee el usuario de la base de datos. |
| 15 | `withOpacity` y `surfaceVariant` obsoletos. | `withValues(alpha:)` y `surfaceContainerHighest`. |
| 16 | Comentario con `[cite: 1]`, mixin sin uso, sintaxis `Key? key`. | Limpiado; `super.key`. |
| 17 | `SessionSummaryCard`: `onShare` obligatorio pero nulo; colores fijos. | Opcional (sin él no hay botón); colores del tema. |
| 18 | Condición de carrera al abrir la BD; mapas sin tipar; medias con 14 decimales; sin estados vacío/error. | Apertura compartida (y reintentable); modelos tipados; formato según idioma (`87,3°`); estados vacío y error con *Reintentar*; `RehabRepository` como contrato. |
| 19 | `ModalRoute.of(context)!` fallaba sin argumentos. | `onGenerateRoute` con argumentos tipados y aviso si faltan. |
| 20 | `pubspec`: SDK declarado `>=3.0.0` frente a lo que realmente exigía el `pubspec.lock` (Dart ≥3.13 / Flutter ≥3.47); `intl` fijo; lints desalineados. | `sdk: ^3.13.0`, `flutter: >=3.47.0`, `intl: ^0.20.3`, `flutter_lints: ^6` en app y paquete. |
| 21 | Finales de línea mezclados; textos «A new Flutter project»; sin VS Code ni README útil. | LF + `.gitattributes`/`.editorconfig`; web actualizado; `.vscode/` (launch, settings, extensiones); README completo. |

## Mejoras añadidas

- `MoviRehabController`: cuenta de operaciones en curso (`isLoading` fiable), último error, protección frente a `notifyListeners` tras `dispose`, y gestión de la sesión guiada.
- `AngleGauge` y `SessionSummaryCard` aceptan textos y formateador para poder localizarse desde la app.
- Tests: 13 en el paquete de componentes y 46 en la app (modelos, controlador con repositorio en memoria y pantallas, incluido el flujo completo Sesión → Resumen).

## Cómo se comprobó (y qué no)

Dentro del entorno de trabajo **no había SDK de Flutter** (la descarga está bloqueada), así que **no se ejecutó `flutter analyze` ni `flutter test`**. Lo que sí se hizo:

- Análisis de sintaxis y formateo de los 35 archivos `.dart` con el Dart SDK 3.13.7.
- El SQL del proyecto se ejecutó en SQLite real: esquema, consultas, desempates, cascadas y la migración v1→v2 (incluido el fallo original).
- Validación de los `.arb` (claves, placeholders y orden de parámetros contra el código del generador `gen-l10n` de Flutter 3.47.5).
- Comprobación cruzada de que cada texto usado existe en los `.arb` con el número correcto de argumentos, y de que todos los imports y paquetes están declarados.
- Las APIs de Flutter usadas se contrastaron con el código fuente de Flutter 3.47.5 (el mismo commit que declara tu `.metadata`).
- Revisión manual final de cada test razonando qué hay en pantalla en cada paso.

**Primera vez que lo ejecutes:** `flutter pub get`, `flutter analyze` y `flutter test`. Si aparece algún aviso, dímelo y lo corrijo.
