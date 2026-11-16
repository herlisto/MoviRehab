import 'dart:async';
import 'dart:math' as math;

import 'package:movirehab/services/fuente_movimiento.dart';

/// Fuente controlada por el test.
class FuenteFalsa implements FuenteMovimiento {
  FuenteFalsa({this.disponible = true});

  @override
  final bool disponible;

  final StreamController<MuestraAceleracion> _controlador =
      StreamController<MuestraAceleracion>.broadcast();

  @override
  Stream<MuestraAceleracion> muestras() => _controlador.stream;

  bool get hayOyentes => _controlador.hasListener;

  /// Emite la gravedad con el móvil inclinado [grados] respecto a la posición
  /// de partida.
  void inclinar(double grados) {
    final rad = grados * math.pi / 180;
    _controlador.add(
      MuestraAceleracion(0, 9.81 * math.cos(rad), 9.81 * math.sin(rad)),
    );
  }

  void fallar() => _controlador.addError(StateError('sin sensor'));

  Future<void> cerrar() => _controlador.close();
}
