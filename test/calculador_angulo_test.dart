import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/services/calculador_angulo.dart';

const double _g = 9.81;

/// Gravedad medida cuando el móvil está inclinado [grados] sobre el eje X.
(double, double, double) _inclinado(double grados) {
  final rad = grados * math.pi / 180;
  return (0, _g * math.cos(rad), _g * math.sin(rad));
}

void main() {
  group('CalculadorAngulo', () {
    test('sin muestras ni calibración no hay ángulo', () {
      final calculador = CalculadorAngulo();

      expect(calculador.grados, isNull);
      expect(calculador.calibrado, isFalse);
      expect(calculador.calibrar(), isFalse);
    });

    test('calibrado en la posición de partida da 0°', () {
      final calculador = CalculadorAngulo(suavizado: 1);
      final (x, y, z) = _inclinado(0);

      calculador.procesar(x, y, z);
      expect(calculador.calibrar(), isTrue);

      expect(calculador.procesar(x, y, z), closeTo(0, 1e-6));
    });

    test('mide ángulos de inclinación respecto a la referencia', () {
      final calculador = CalculadorAngulo(suavizado: 1);
      final (x0, y0, z0) = _inclinado(0);
      calculador.procesar(x0, y0, z0);
      calculador.calibrar();

      for (final objetivo in [15.0, 45.0, 90.0, 135.0, 180.0]) {
        final (x, y, z) = _inclinado(objetivo);
        expect(calculador.procesar(x, y, z), closeTo(objetivo, 1e-6));
      }
    });

    test('el ángulo no depende de la intensidad de la gravedad medida', () {
      final calculador = CalculadorAngulo(suavizado: 1);
      calculador.procesar(0, _g, 0);
      calculador.calibrar();

      // 8 m/s² a 60° (dentro del rango válido).
      final rad = 60 * math.pi / 180;
      final angulo = calculador.procesar(
        0,
        8 * math.cos(rad),
        8 * math.sin(rad),
      );

      expect(angulo, closeTo(60, 1e-6));
    });

    test('descarta muestras dominadas por sacudidas', () {
      final calculador = CalculadorAngulo(suavizado: 1);
      calculador.procesar(0, _g, 0);
      calculador.calibrar();

      // 30 m/s² (golpe) y 0 (caída libre) no deben mover el ángulo.
      expect(calculador.procesar(30, 0, 0), closeTo(0, 1e-6));
      expect(calculador.procesar(0, 0, 0), closeTo(0, 1e-6));
    });

    test('el filtro suaviza un cambio brusco', () {
      final calculador = CalculadorAngulo(suavizado: 0.3);
      calculador.procesar(0, _g, 0);
      calculador.calibrar();

      final (x, y, z) = _inclinado(90);
      final primera = calculador.procesar(x, y, z)!;
      var ultima = primera;
      for (var i = 0; i < 40; i++) {
        ultima = calculador.procesar(x, y, z)!;
      }

      expect(primera, lessThan(45));
      expect(ultima, closeTo(90, 1));
    });

    test('recalibrar fija la nueva posición como 0°', () {
      final calculador = CalculadorAngulo(suavizado: 1);
      final (x, y, z) = _inclinado(30);
      calculador.procesar(x, y, z);
      calculador.calibrar();

      expect(calculador.procesar(x, y, z), closeTo(0, 1e-6));
    });

    test('reiniciar olvida muestras y referencia', () {
      final calculador = CalculadorAngulo();
      calculador.procesar(0, _g, 0);
      calculador.calibrar();

      calculador.reiniciar();

      expect(calculador.calibrado, isFalse);
      expect(calculador.tieneMuestra, isFalse);
      expect(calculador.grados, isNull);
    });
  });
}
