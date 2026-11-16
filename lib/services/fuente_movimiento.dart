import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:sensors_plus/sensors_plus.dart';

/// Una muestra del acelerómetro (m/s², incluye la gravedad).
class MuestraAceleracion {
  final double x;
  final double y;
  final double z;

  const MuestraAceleracion(this.x, this.y, this.z);
}

/// Origen de las muestras de movimiento. Se abstrae para poder sustituirlo por
/// una fuente falsa en los tests y en plataformas sin sensor (Windows).
abstract class FuenteMovimiento {
  /// `true` si el dispositivo puede aportar muestras de acelerómetro.
  bool get disponible;

  /// Flujo de muestras. Cada llamada crea una suscripción independiente.
  Stream<MuestraAceleracion> muestras();
}

/// Acelerómetro real del móvil (Android e iOS) mediante `sensors_plus`.
class FuenteAcelerometro implements FuenteMovimiento {
  const FuenteAcelerometro();

  @override
  bool get disponible =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Stream<MuestraAceleracion> muestras() {
    return accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .map((evento) => MuestraAceleracion(evento.x, evento.y, evento.z));
  }
}

/// Plataformas sin acelerómetro (Windows, Linux, Web): la sesión guiada usa el
/// modo manual.
class FuenteNoDisponible implements FuenteMovimiento {
  const FuenteNoDisponible();

  @override
  bool get disponible => false;

  @override
  Stream<MuestraAceleracion> muestras() => const Stream.empty();
}

/// Elige la fuente adecuada para la plataforma actual.
FuenteMovimiento crearFuenteMovimiento() {
  const real = FuenteAcelerometro();
  return real.disponible ? real : const FuenteNoDisponible();
}
