import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/services/contador_repeticiones.dart';

void main() {
  final inicio = DateTime(2026, 11, 12, 10);
  DateTime t(int segundos) => inicio.add(Duration(seconds: segundos));

  group('ContadorRepeticiones', () {
    test('los umbrales salen del objetivo', () {
      final contador = ContadorRepeticiones(objetivoGrados: 100);

      expect(contador.umbralSubida, 80);
      expect(contador.umbralBajada, 30);
    });

    test('cuenta una repetición al subir y volver a la posición inicial', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);

      expect(contador.procesar(0, t(0)), isFalse);
      expect(contador.procesar(50, t(1)), isFalse);
      expect(contador.procesar(85, t(2)), isFalse);
      expect(contador.arriba, isTrue);
      expect(contador.procesar(60, t(3)), isFalse);
      expect(contador.procesar(10, t(4)), isTrue);

      expect(contador.repeticiones, 1);
      expect(contador.arriba, isFalse);
    });

    test('no cuenta si no se llega a la zona alta', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);

      for (final grados in [0.0, 40, 60, 20, 0, 50, 10]) {
        contador.procesar(grados, t(grados.toInt()));
      }

      expect(contador.repeticiones, 0);
    });

    test('el ruido entre los dos umbrales no cuenta de más', () {
      final contador = ContadorRepeticiones(objetivoGrados: 100);

      contador.procesar(85, t(0));
      // Oscila entre 40° y 75°: nunca baja del umbral de bajada (30°).
      for (var i = 1; i <= 10; i++) {
        contador.procesar(i.isEven ? 40 : 75, t(i));
      }
      expect(contador.repeticiones, 0);

      contador.procesar(20, t(20));
      expect(contador.repeticiones, 1);
    });

    test('varias repeticiones seguidas', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);
      var segundo = 0;

      for (var i = 0; i < 5; i++) {
        contador.procesar(0, t(segundo += 1));
        contador.procesar(80, t(segundo += 1));
        contador.procesar(5, t(segundo += 1));
      }

      expect(contador.repeticiones, 5);
    });

    test('descarta rebotes más rápidos que la pausa mínima', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);

      contador.procesar(80, t(0));
      expect(contador.procesar(5, t(1)), isTrue);
      // Otra subida y bajada 100 ms después: es un rebote.
      contador.procesar(80, inicio.add(const Duration(milliseconds: 1100)));
      expect(
        contador.procesar(5, inicio.add(const Duration(milliseconds: 1200))),
        isFalse,
      );

      expect(contador.repeticiones, 1);
    });

    test('maximo guarda el mayor ángulo alcanzado', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);

      for (final grados in [10.0, 70, 95.5, 40, 5]) {
        contador.procesar(grados, t(grados.toInt()));
      }

      expect(contador.maximo, 95.5);
    });

    test('reiniciar pone a cero repeticiones y máximo', () {
      final contador = ContadorRepeticiones(objetivoGrados: 90);
      contador.procesar(85, t(0));
      contador.procesar(5, t(2));

      contador.reiniciar();

      expect(contador.repeticiones, 0);
      expect(contador.maximo, 0);
    });

    test('funciona con recorridos pequeños (20°)', () {
      final contador = ContadorRepeticiones(objetivoGrados: 20);

      contador.procesar(17, t(0));
      expect(contador.procesar(4, t(2)), isTrue);
      expect(contador.repeticiones, 1);
    });
  });
}
