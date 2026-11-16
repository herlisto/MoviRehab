import 'dart:math' as math;

/// Calcula el ángulo de giro de un segmento corporal a partir del vector de
/// gravedad que mide el acelerómetro del móvil.
///
/// El móvil se sujeta al segmento (brazo, pierna...). Al calibrar en la
/// posición de partida se guarda la dirección de la gravedad; el ángulo es
/// el que forma la dirección actual con la de referencia (0° a 180°).
///
/// Limitación física: el acelerómetro solo detecta cambios de **inclinación**.
/// Un giro alrededor del eje vertical (la gravedad) no cambia la medida.
///
/// Es lógica pura de Dart: no depende de Flutter ni de ningún plugin.
class CalculadorAngulo {
  /// [suavizado] es el coeficiente del filtro exponencial (0 < valor <= 1);
  /// 1 desactiva el filtro y valores bajos suavizan más (pero reaccionan más
  /// despacio).
  CalculadorAngulo({this.suavizado = 0.3})
    : assert(suavizado > 0 && suavizado <= 1, 'suavizado debe estar en (0, 1]');

  final double suavizado;

  /// Aceleración mínima y máxima (m/s²) aceptada. Fuera de este rango la
  /// muestra está dominada por sacudidas, no por la gravedad (≈ 9,81), y se
  /// descarta.
  static const double _minimo = 6.0;
  static const double _maximo = 14.0;

  double? _x;
  double? _y;
  double? _z;

  double? _referenciaX;
  double? _referenciaY;
  double? _referenciaZ;

  /// `true` cuando ya hay una posición de referencia.
  bool get calibrado => _referenciaX != null;

  /// `true` cuando ya se ha recibido alguna muestra válida.
  bool get tieneMuestra => _x != null;

  /// Introduce una muestra del acelerómetro (m/s², con gravedad).
  ///
  /// Devuelve el ángulo actual en grados, o `null` si todavía no se puede
  /// calcular (sin calibrar) o si la muestra se descartó y no hay ángulo
  /// previo.
  double? procesar(double x, double y, double z) {
    final modulo = math.sqrt(x * x + y * y + z * z);
    final valida = modulo >= _minimo && modulo <= _maximo;

    if (valida) {
      final anteriorX = _x;
      final anteriorY = _y;
      final anteriorZ = _z;
      if (anteriorX == null || anteriorY == null || anteriorZ == null) {
        _x = x;
        _y = y;
        _z = z;
      } else {
        _x = anteriorX + suavizado * (x - anteriorX);
        _y = anteriorY + suavizado * (y - anteriorY);
        _z = anteriorZ + suavizado * (z - anteriorZ);
      }
    }
    return grados;
  }

  /// Fija la posición actual como 0°. Devuelve `false` si aún no hay muestras.
  bool calibrar() {
    final x = _x;
    final y = _y;
    final z = _z;
    if (x == null || y == null || z == null) return false;
    final modulo = math.sqrt(x * x + y * y + z * z);
    if (modulo == 0) return false;
    _referenciaX = x / modulo;
    _referenciaY = y / modulo;
    _referenciaZ = z / modulo;
    return true;
  }

  /// Ángulo actual respecto a la referencia (`null` si no se puede calcular).
  double? get grados {
    final x = _x;
    final y = _y;
    final z = _z;
    final rx = _referenciaX;
    final ry = _referenciaY;
    final rz = _referenciaZ;
    if (x == null ||
        y == null ||
        z == null ||
        rx == null ||
        ry == null ||
        rz == null) {
      return null;
    }
    final modulo = math.sqrt(x * x + y * y + z * z);
    if (modulo == 0) return null;
    final coseno = ((x * rx + y * ry + z * rz) / modulo).clamp(-1.0, 1.0);
    return math.acos(coseno) * 180 / math.pi;
  }

  /// Olvida muestras y referencia.
  void reiniciar() {
    _x = null;
    _y = null;
    _z = null;
    _referenciaX = null;
    _referenciaY = null;
    _referenciaZ = null;
  }
}
