import 'dart:math' as math;

/// Cuenta repeticiones a partir de una serie de ángulos (en grados).
///
/// Una repetición es un recorrido completo: el ángulo sube por encima del
/// *umbral de subida* y vuelve por debajo del *umbral de bajada*. Usar dos
/// umbrales distintos (histéresis) evita contar de más por el ruido del
/// sensor cuando el ángulo oscila cerca de un único umbral.
///
/// Es lógica pura de Dart (el reloj se recibe como parámetro para poder
/// probarla).
class ContadorRepeticiones {
  ContadorRepeticiones({
    required this.objetivoGrados,
    this.fraccionSubida = 0.8,
    this.fraccionBajada = 0.3,
    this.pausaMinima = const Duration(milliseconds: 500),
  }) : assert(objetivoGrados > 0, 'El objetivo debe ser mayor que 0'),
       assert(fraccionBajada < fraccionSubida);

  /// Recorrido del ejercicio en grados.
  final int objetivoGrados;

  /// Fracción del objetivo que hay que superar para considerar «arriba».
  final double fraccionSubida;

  /// Fracción del objetivo por debajo de la cual se considera «abajo».
  final double fraccionBajada;

  /// Tiempo mínimo entre dos repeticiones (descarta rebotes).
  final Duration pausaMinima;

  int _repeticiones = 0;
  double _maximo = 0;
  bool _arriba = false;
  DateTime? _ultimaRepeticion;

  int get repeticiones => _repeticiones;

  /// Mayor ángulo alcanzado desde el último reinicio.
  double get maximo => _maximo;

  /// `true` mientras el ángulo está en la zona alta (entre subida y bajada).
  bool get arriba => _arriba;

  /// Ángulo a partir del cual se considera que se ha llegado «arriba».
  double get umbralSubida => math.max(objetivoGrados * fraccionSubida, 5);

  /// Ángulo por debajo del cual se considera que se ha vuelto «abajo».
  double get umbralBajada =>
      math.min(objetivoGrados * fraccionBajada, umbralSubida - 3);

  /// Procesa un ángulo. Devuelve `true` si con esta muestra se completa una
  /// repetición.
  bool procesar(double grados, DateTime ahora) {
    if (grados > _maximo) _maximo = grados;

    if (!_arriba) {
      if (grados >= umbralSubida) _arriba = true;
      return false;
    }

    if (grados > umbralBajada) return false;

    // Ha vuelto abajo: se cierra el ciclo.
    _arriba = false;
    final ultima = _ultimaRepeticion;
    if (ultima != null && ahora.difference(ultima) < pausaMinima) {
      return false;
    }
    _ultimaRepeticion = ahora;
    _repeticiones++;
    return true;
  }

  /// Vuelve a cero repeticiones y máximo (conserva el estado «arriba/abajo»
  /// para no contar una repetición a medias).
  void reiniciar() {
    _repeticiones = 0;
    _maximo = 0;
    _ultimaRepeticion = null;
  }
}
