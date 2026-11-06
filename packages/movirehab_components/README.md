# movirehab_components

Componentes visuales propios de MoviRehab (Bloque D).

| Componente | Descripción |
| --- | --- |
| `AngleGauge` | Medidor de rango articular: grados actuales / objetivo, barra animada y aviso `onTargetReached` (se dispara una vez al llegar a la meta, también si nace ya en ella). |
| `SessionSummaryCard` | Tarjeta de resumen de sesión: título, fecha, nº de ejercicios y media de grados, con botón opcional de compartir y `onTap`. |

Los textos por defecto están en español y se pueden sustituir mediante parámetros
(`title`, `holdMessage`, `reachedMessage`, `exercisesLabel`, `averageLabel`, ...)
para localizarlos desde la aplicación. Los colores salen del `ColorScheme` del tema.

```dart
AngleGauge(
  currentDegrees: 45,
  targetDegrees: 90,
  onTargetReached: () => debugPrint('¡Meta alcanzada!'),
);
```

Tests: `flutter test` dentro de esta carpeta.
